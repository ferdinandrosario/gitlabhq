module API
  # Git Tags API
  class Tags < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
      # Get a project repository tags
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/tags
      get ":id/repository/tags" do
        present user_project.repo.tags.sort_by(&:name).reverse,
                with: Entities::RepoTag, project: user_project
      end

      # Create tag
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   tag_name (required) - The name of the tag
      #   ref (required) - Create tag from commit sha or branch
      #   message (optional) - Specifying a message creates an annotated tag.
      # Example Request:
      #   POST /projects/:id/repository/tags
      post ':id/repository/tags' do
        authorize_push_project
        message = params[:message] || nil
        result = CreateTagService.new(user_project, current_user).
          execute(params[:tag_name], params[:ref], message, params[:release_description])

        if result[:status] == :success
          present result[:tag],
                  with: Entities::RepoTag,
                  project: user_project
        else
          render_api_error!(result[:message], 400)
        end
      end

      # Add release notes to tag
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   tag (required) - The name of the tag
      #   description (required) - Release notes with markdown support
      # Example Request:
      #   PUT /projects/:id/repository/tags
      put ':id/repository/:tag/release', requirements: { tag: /.*/ } do
        authorize_push_project
        required_attributes! [:description]
        release = user_project.releases.find_or_initialize_by(tag: params[:tag])
        release.update_attributes(description: params[:description])

        present release, with: Entities::Release
      end
    end
  end
end
