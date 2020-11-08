
# Contribute to the `PEMA` repo!

:rocket:  :metal: Thank you all for taking the time to contribute! :rocket:  :metal:

The following is a set of guidelines for contributing, in terms of guidelines, not rules.
Feel free to contribute to this document as in the rest of the repo! :wink:

## Table of Contents

  * [Dependencies](#dependencies)
  * [Fork `PEMA` repository to build your own repo](#fork-pema-repository-to-build-your-own-repo)
  * [Prepare to contribute!](#prepare-to-contribute)
    + [GitFlow workflow](#gitflow-workflow)
    + [Create new branch for your work](#create-new-branch-for-your-work)
  * [Make your contributions on your branch](#make-your-contributions-on-your-branch)
  * [Pull request (PR) and the job is done](#pull-request-pr-and-the-job-is-done)
  * [Review](#review)
  * [Acknowledgements](#acknowledgements)

   
## Dependencies

* `git` (see [Getting Started with Git](https://help.github.com/en/github/using-git/getting-started-with-git-and-github))
* configured GitHub account
* you also need to have [Docker](https://www.docker.com/get-started) on your machine as PEMA is a containerized-oriented software

In terms of contributing to the PEMA image you need to set you code feasible to run on its PEMA's acutal container, meaning a container.
So, before you start coding, you need to make sure that you can build your own images using the `docker build` command, and run your code
over there as part of the PEMA environment. 

To have a look on what you need to end up with, you can just download the current version of PEMA and run a small test. 

Clone the repository, 

    git clone git@github.com:hariszaf/pema.git pema
    cd pema
    git branch -vv

the last command should tell you that you are in `develop` branch.

Now you may try to run current version of PEMA locally by making use of the [```analysis_directory```](https://github.com/hariszaf/pema/tree/master/analysis_directory) following the instructions presented on the [PEMA tutorial](https://docs.google.com/presentation/d/1lVH23DPa2NDNBhVvOTRoip8mraw8zfw8VQwbK4vkB1U/edit?fbclid=IwAR14PpWfPtxB8lLBBnoxs7UbG3IJfkArrJBS5f2kRA__kvGDUb8wiJ2Cy_s#slide=id.g464fa2cc59_0_57)



## Fork `PEMA` repository to build your own repo

Working directly in the original PEMA repository is not possible to you, therefore you should create your own fork. 

This way you can modify the code and when the job is done send a pull request to merge your changes with the original repository.

Here are the steps to do that:

1. Login on `GitHub`
2. Go to [PEMA repository](https://github.com/hariszaf/pema)
3. Click the 'Fork' button
4. Choose your profile and wait a bit!
6. Now you are ready to contribute!

You may find further information regarding `fork` over [here](https://guides.github.com/activities/forking/)


**Verify if your fork works**

Go out of `pema` directory you built in the *Get the development branch of PEMA* step 

    cd ..

clone your repository and checkout to the ```develop``` branch

    git clone git@github.com:<your_github_profile_name>/pema.git pema_fork
    cd pema_fork
    git checkout develop
    git branch -vv
    git pull

see commits

    git log

You should be able to see exactly the same commits as in `pema` repository now.

## Prepare to contribute!

### GitFlow workflow

PEMA is using the [GitFlow](http://nvie.com/posts/a-successful-git-branching-model/) workflow. 
Each repository using this model should contain two main branches:

* master - release-ready version of the library
* develop - development version of the library
 
and could contain various supporting branches for new features and hotfixes. 

As a contributor you'll be adding new features or fixing bugs in the **development** version. 
This means that **for each contribution** you should **create a new branch originating from the develop branch**, 
modify it and send a pull request in order to merge it, again with the develop branch.

### Create new branch for your work

Make sure you're in **develop branch** running

    git status
    
The first line of the returned message should be

    On branch develop
    

Now you need to pick a name for your new branch that doesn't already exist. 
Checks existing remote branches with

    git branch -a


Let's assume you want to name it `greatest_branch_ever`.

Create new branch first locally

    git branch greatest_branch_ever
    git checkout greatest_branch_ever

and then push it to your fork

    git push -u my_fork greatest_branch_ever

Verify your new branch by running

    git branch -vv

**Attention!**
* Note that the `-u` switch also sets up the tracking of the remote branch. Your new branch now is now ready to contribute!
* Note that without the `-u` switch you wouldn't see the tracking information for your new branch. You can verify that with ```git remote -v```.

You can see your newly created remote branch also on GitHub on your fork repo, not in the initial PEMA repo! 


## Make your contributions on your branch

Before contributiong to a library by adding a new feature, or a bugfix, 
you need **always** to contact the PEMA developers team (pema@hcmr.gr) or by opening an issue.

You also need to run your version locally to make sure that your contribution leads to a robust new Docker and Singularity image.

To do so, you need to re-build ```pema``` or ```pemabase``` Docker images and for the primer, the correponding Singularity file as
you can see [here](https://github.com/hariszaf/pema/tree/master/singularity).

It is your images that will be tested by the PEMA group to review your contribution. 


Now you can push your changes to the remote branch

    git push my_fork feature/the_fastest_sampling_algo_ever

or if your local branch is tracking the remote one, just

    git push

## Pull request (PR) and the job is done

Your work is already on `GitHub` but as already mentioned, just on your fork. 

You can now go there and click "Compare and pull request" button or the "New pull request" button.

Add title and description and click the "Create pull request" button.

## Review

After creating a pull request your code will be reviewed and if there are no objections and your contribution is valid, your changes will be merged.

If you see some comments under the pull request and/or under specific lines of your code, you have to make the required changes, commit them and push to your branch. 

Those changes will also be part of the same pull request.

This procedure will be repeated until the code is ready for merging.


## Acknowledgements

:tada::tada: Contributing takes quite some time and energy so we thank you all for your effort and it is highy appreciated! A list with all the PEMA contributors will be soon available! :tada::tada:



