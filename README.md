# FuruGelato

FuruGelato is an automate task executions for Furucombo through user's DSProxy powered by Gelato. User's tasks can be executed once it meets the condition defined through resolver. TaskTimer enables the task that matches the definition to be executed repeatedly every defined time period.

## Description

### FuruGelato

A task is an execution being triggered through a DSProxy. The task will be verified through a resolver when creating and executing. The applicable action is defined in the resolver. The resolver is whitelisted in FuruGelato by the owner.

### TaskTimer

TaskTimer is a resolver implementation. The task being created through the TaskTimer will be able to be executed repeatedly after a certain time period defined in TaskTimer.

Below is the flow in this example.

1. DSProxy calls `createTask` through `CreateTaskHandler`.

2. After `period` defined in TaskTimer, the task can be executed and Gelato calls `exec`.

3. Calls DSProxy `execute` with the action defined in TaskTimer and the given `exectionData`. The execution time will be updated in TaskTimer.

4. After `period` defined in TaskTimer, the task can be executed again.

## Setup

1. Copy .env

```
cp .env.example .env
```

2. Install dependencies

```
yarn
```

2. Compile

```
yarn compile
```

3. Run tests

```
yarn test
```
