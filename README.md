# GitHub Action to download Job logs

This action will download job-level logs for the GitHub Action Workflow. By default, the action will only download logs for the past 24 hours.


## Usage

### Example 1: `workflow.yml`

```yaml
on: [push]

jobs:
  logs-download:
    name: Download GH action logs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2.0.0
      - name: Download 24hrs Old Logs
        uses: pawanbahuguna/action-logs/@v1.0.1
        env: 
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
          GH_REPO: ${{ github.repository }}
```

### Example 2: `workflow.yml`

```yaml
on: [push]

jobs:
  logs-download:
    name: Download GH action logs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2.0.0
      - name: Download Logs
        uses: pawanbahuguna/action-logs/@v1.0.1
        env: 
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
          GH_REPO: ${{ github.repository }}
          ONLY_24: false # Default is true [Optional]
          LOGS_DIR: <Directory name> # Default is jobs-log [Optional]
```


### Example 3: `workflow-schedule.yml`

```yaml
on:
  schedule:
    - cron:  '15 00 * * *'

jobs:
  logs-download:
    name: Download GH action logs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2.0.0
      - name: Download Logs
        uses: pawanbahuguna/action-logs/@v1.0.1
        env: 
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
          GH_REPO: ${{ github.repository }}
          ONLY_24: false # Default is true [Optional]
          LOGS_DIR: <Directory name> # Default is jobs-log [Optional]
```

## GitHub Token Permission

Generate [fine-grained token](https://github.com/settings/tokens?type=beta) for the repo with **Read access to actions, code, and metadata**


## License

This project is distributed under the [MIT license](LICENSE.md).
