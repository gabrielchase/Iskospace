defmodule Iskospace.PostController do
	use Iskospace.Web, :controller

	alias Iskospace.Post
	alias Iskospace.User

	plug :scrub_params, "post" when action in [:create, :update]

	def index(conn, %{"user_id" => user_id}) do
		posts_owner = Repo.get!(User, user_id |> String.to_integer)
		posts = Repo.all(assoc(posts_owner, :posts))
		render(conn, "index.html", posts: posts, posts_owner: posts_owner)
	end

	def show(conn, %{"id" => post_id}) do
		post = Repo.get!(Post, post_id)
			|> Repo.preload(:user)
			|> Repo.preload(comments: :user)

		comment_changeset = post 
			|> build_assoc(:comments)
			|> Iskospace.Comment.changeset(%{})

		render(conn, "show.html", post: post, comment_changeset: comment_changeset)
	end

	def new(conn, _params) do
		changeset = conn.assigns[:user]
		|> build_assoc(:posts)
		|> Post.changeset()
		render(conn, "new.html", changeset: changeset)
	end

	def create(conn, %{"post" => %{"tags" => tags} = post_params})  do
		IO.inspect post_params
		IO.inspect tags
		changeset = conn.assigns[:user]
		|> build_assoc(:posts)
		|> Post.changeset(post_params)

		case Repo.insert(changeset) do
			{:ok, _post} ->
				conn
				|> put_flash(:info, "Successfully made post")	 
				|> redirect(to: user_post_path(conn, :index, conn.assigns[:user]))
			{:error, changeset}
				render(conn, "new.html", changeset: changeset)
		end
	end	

	def edit(conn, %{"id" => post_id}) do
		post = Repo.get!(assoc(conn.assigns[:user], :posts), post_id)	
		changeset = Post.changeset(post)
		render(conn, "edit.html", changeset: changeset, post: post)
	end

	def update(conn, %{"id" => post_id, "post" => post_params}) do
		old_post = Repo.get!(assoc(conn.assigns[:user], :posts), post_id)		
		changeset = Post.changeset(old_post, post_params)
		
		case Repo.update(changeset) do
			{:ok, new_post} ->
				conn 
				|> put_flash(:info, "Successfully updated post")
				|> redirect(to: user_post_path(conn, :show, conn.assigns[:user], new_post))
			{:error, changeset} -> 
				render(conn, "edit.html", changeset: changeset, post: old_post)
		end
	end

	def delete(conn , %{"id" => post_id}) do
		post = Repo.get!(assoc(conn.assigns[:user], :posts), post_id)
		|> Repo.delete!

		conn
		|> put_flash(:info, "Post deleted")
		|> redirect(to: user_path(conn, :show, conn.assigns[:user]))
	end

	# defp get_tags(changeset) do
	# 	tags = get_change(changeset, :tags)
	# 		|> to_string
	# 		|> String.split(",")
	# 		|> Enum.map(&save_to_tag_database/1)
	# 	changeset
	# end

	defp save_to_tag_database(tag) do
		tag 
		|> String.trim(" ")
		|> IO.inspect 
	end
end