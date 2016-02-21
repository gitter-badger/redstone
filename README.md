redstone
========

[![Join the chat at https://gitter.im/nikhiljha/redstone](https://badges.gitter.im/nikhiljha/redstone.svg)](https://gitter.im/nikhiljha/redstone?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A distributed, infinite-player Minecraft server that runs on Node.js.

Redstone can support theoretically infinite players in one game world by transparently breaking up the work to multiple servers. Being based on Node.js, it has blazing fast IO performance, which means lower resource consumption and lower latency than standard Java servers.

## Status
**WARNING:** This project is currently considered unstable and experimental, it is not ready for production yet.

Redstone currently only supports creative mode, and is missing much of the game logic. The framework for the clustering of servers is present and functional, but could use some reorganization.
This was originally a private project and has been taken over by me.

## Usage

First, make sure you have a MongoDB instance running. By default, Redstone connects to a MongoDB server on `localhost`, but if neccessary, you can configure the Mongo URI via the `database` parameter in `config.coffee`.

Install the dependencies:
```
npm install
```

### Simple mode (all components in one process)
```
coffee bin/redstone
```

### Distributed (components running on separate processes or servers)
First, you must run one master component:
```
coffee bin/redstone -m
```

Next, you will need to start the other components (servers and connectors). When starting them, you will need to specify the hostname of the master. You must start at least one server and at least one connector, but you may start as many as you like.
```
coffee bin/redstone -s --master=<HOSTNAME OF MASTER>
coffee bin/redstone -c --master=<HOSTNAME OF MASTER>
```

**NOTE:** If multiple components are running on the same machine, you must set the control port to a unique port, e.g.:
```
coffee bin/redstone -s --master=localhost --control=8001
coffee bin/redstone -c --master=localhost --control=8002
```

Once your components spin up, you should be able to connect to the connector(s) via your Minecraft client.
