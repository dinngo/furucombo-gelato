# FuruGelato

Automate task executions for Furucombo.

## Description

- A Task can be a series of function calls to multiple contracts. And this string of calls can be whitelisted by Furucombo to ensure only certain calls are allowed.

- Condition of execution can be set in the function with require statements.

Below is the flow in this example.

1. DSProxy calls `createTask` through `CreateTaskHandler`.

2. When condition is met, every 3 minutes, Gelato calls `exec`.

3. DSProxy delegateCalls `batchExec` which then calls `Counter` contract, increasing the count.

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
