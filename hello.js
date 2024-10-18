var addon = require('bindings')('sodium-native')

console.log('This should be eight:', addon.add('hello', 4, 8192))