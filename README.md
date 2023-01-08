This repository contains a shell script to ship GitHub PR details to Elastic Search.

-------------

**Files:** 
```
      1. getGithubPR.shq
```

## How to run the above scripts

1.  Modify the following variables in the script.
    - OWNER to GitHub owner name on line 7.
    - REPO to GitHub repsitory name on line 7.
    - ES_URL to Elastic Search URL on line 98.
    - index to Elastic Search Index name on line 98.
    - type to Elastci Search Index type name on line 98.

2. Now, to run the script:
    ```
    ./getGithubPR.sh
    ```