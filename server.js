var forever = require('forever'),
    child = new(forever.Monitor)('app.coffee', {
        'silent': false,
        'pidFile': 'pids/app.pid',
        'command': 'coffee',
        'watch': true,
        'watchDirectory': '.',      // Top-level directory to watch from.
        'watchIgnoreDotFiles': true, // whether to ignore dot files
        'watchIgnorePatterns': [], // array of glob patterns to ignore, merged with contents of watchDirectory + '/.foreverignore' file
        'logFile': 'logs/forever.log', // Path to log output from forever process (when daemonized)
        'outFile': 'logs/forever.out', // Path to log output from child stdout
        'errFile': 'logs/forever.err'
    });
child.start();
forever.startServer(child);