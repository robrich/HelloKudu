Custom Git Deploy to Azure
==========================

This repository is the companion code to the Custom Git Deploy to Azure talk.  You can find the slides at [https://robrich.org/slides/custom-git-deploy-to-azure/#/](https://robrich.org/slides/custom-git-deploy-to-azure/#/).

Using this repository
---------------------

1. Look at `deploy.cmd` -- that's where the magic happens.  This file was generated by running: `azure site deploymentscript --aspWAP src\Web\Web.csproj -s HelloKudu.sln`

2. run NuGet Restore and `npm install` to get all the libraries in place.


Topics in this presentation
---------------------------

- Setup Git Deployment to Azure App Service
- `git push azure master` to deploy code to Azure
- View the deployment logs in both the [Azure portal](https://portal.azure.com/) and the [Classic Portal](https://manage.windowsazure.com/)
- Use the [Azure Client Tools](https://npmjs.org/azure-cli) to template the deployment script
- Modify the deployment script to add:
  - Run unit tests
  - Minify JavaScript
  - Run ESLint
  - Set the git hash into the app so it displays on the page
  - Migrate the database
  - Verify the site is running
- Debug Kudu deployments with the Kudu Console

Once we're done, users need only `git push azure` to run all these steps.
