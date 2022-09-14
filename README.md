# Unity Package Template

Rapidly set up a [Custom Unity Package](https://docs.unity3d.com/Manual/CustomPackages.html) with this template!

![](https://github.com/Phantasmic-Games/Unity-Package-Template/blob/main/.github/workflows/Using%20Template.gif)

## How to Use
### 'Use this Template' Method
This is the most streamlined and the quickest method. Click `Use this template`, fill out your new repo's details.
- **Creating Repo With Organization as the Owner:** A GitHub workflow is automatically triggered and the package is configured as follows. Organization fields and file names are filled with the repo owner's name (aka GitHub Organization name) and Package fields and file names are filled with the repo's name.

- **Creating Repo With User as the Owner:** Go to `Actions - Initialize - Run workflow` and enter your Organization and Package name. If either is left blank, the workflow will configure the package as it would for an Organization (as explained above).

#### Note:
* If the workflow fails due to access being revoked, go into the repo owner's `Settings - Actions - General - Workflow permissions` and set `Read and write permissions`.

### Manual Set Up Method
Go to `Code - Download ZIP` and extract it in your Unity project's Packages directory. You could manually edit the `package.json` file in the Inspector and rename the Assembly Definition files to match your package name, but this can be automated with the included bash script. Open a command line program that supports bash and at the Package's root directory, run:
```
bash Init.sh
```
Enter your Organization name, then your Package name and the script will initialize the package and delete unnecessary files (.github folder) just like the GitHub workflow.
