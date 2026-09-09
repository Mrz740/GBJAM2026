# Setup Github actions

The project will be automatically built every time someone pushes to `main`. It uses github pages to host the web export of your game on every build, so you need to enable Github Pages on your project.

1. Go to your project on github.com
2. Go to your github project settings
3. In the left menu go to "Pages". You should now be at url like `https://github.com/MY_USERNAME/MY_PROJECT/settings/pages`.
4. Enable Github Pages
5. Set the source to "Github Actions"
6. In Settings > Actions > General, in the category "Workflow permissions" give read and write permissions and save

Now every time you push to your main branch, Github will automatically build and update the web version of your game to the latest changes !

## How do I know the url my latest game is hosted at ?
You can go to your Github project settings > Pages, and you should see at the top of the page : "Your site is live at https://MY_NAME.github.io/MY_PROJECT/", you can save this link, it will always contain the latest version !
Note: you need to have pushed a successful build at least once for this link to appear
