const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');

function runtime() {
    const pending = [];
    const exits = [];
    let nativeExits = 0;
    class ExitStatus { constructor(status) { this.status = status; } }
    const context = {
        Module: { WZVAL_configDirPath: '/warzone2100' }, ExitStatus,
        FS: { syncfs: (populate, callback) => { assert.equal(populate, false); pending.push(callback); }, readdir: () => [] },
        console: { log() {}, warn() {} },
        wz_js_handle_app_exit: error => exits.push(error),
    };
    context.Module._wz_finish_host_return = () => { nativeExits++; context.Module.onExit(); throw new ExitStatus(0); };
    vm.runInNewContext(readFileSync(`${__dirname}/postjs.js`, 'utf8'), context);
    return { ...context, pending, exits, nativeExits: () => nativeExits };
}

test('host shutdown saves before runtime exit and navigation, coalescing concurrent requests', () => {
    const state = runtime();
    state.Module.wzFinishHostReturn();
    state.Module.wzFinishHostReturn();
    assert.equal(state.pending.length, 1);
    assert.equal(state.nativeExits(), 0);
    assert.deepEqual(state.exits, []);
    assert.doesNotThrow(() => state.pending.shift()(null));
    assert.equal(state.nativeExits(), 1);
    assert.deepEqual(state.exits, [undefined]);
    assert.equal(state.pending.length, 0);
});

test('failed persistence leaves the runtime open for a fresh retry', () => {
    const state = runtime();
    state.Module.wzFinishHostReturn();
    state.pending.shift()(new Error('quota'));
    assert.equal(state.nativeExits(), 0);
    assert.match(state.exits[0], /could not be saved/);
    state.Module.wzFinishHostReturn();
    state.pending.shift()(null);
    assert.equal(state.nativeExits(), 1);
});

test('unexpected runtime errors are never swallowed', () => {
    const state = runtime();
    state.Module._wz_finish_host_return = () => { throw new Error('unexpected'); };
    state.Module.wzFinishHostReturn();
    assert.throws(() => state.pending.shift()(null), /unexpected/);
});
