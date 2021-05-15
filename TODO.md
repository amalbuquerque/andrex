# TODO

- Validate each markdown input file has required metadata and format (filename `yyyy-mm-dd-title-kebab-case.md`, `Title` and `Description` metadata fields)
- Provision VPS and automate deployment (dokku?)
- RSS
- Comments

# DONE

- Render a markdown on `priv/static/markdown/2021-04-08-hello-world.md` as a `/blog/2021/04/08/hello-world`
  * Render image present in the `priv/static/images/phoenix.png` on the markdown
- Post tags
- Caching posts and tags
- If no /blog/yyyy/mm/dd/title exists it should redirect to /blog with a Flash if no post exists
- List of posts in the /blog
- List of tags and counts, each point to /blog/tag/<tag>
- Extract the post entry section to its own template, and reuse the `post_url`
- New /blog/tag/<tag> route that lists all the posts with the given tag
  * It should redirect to the homepage with a Flash if no tag exists
- Each `priv/markdown/main` markdown articles are cached and the `GET /:article` route tries to fetch the `"article.md"` from cache
- List of places in the navbar (`lib/andrex_web/templates/layout/app.html.eex`) composed by the `main` articles
  * About -> /about
  * CV -> /cv
  * Blog -> /blog
- Pretty CSS + Navbar with Tailwind CSS 
