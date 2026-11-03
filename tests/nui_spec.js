const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('pm-devcoords/html/index.html', 'utf8');
const script = fs.readFileSync('pm-devcoords/html/script.js', 'utf8');
const ids = [...html.matchAll(/id="([^"]+)"/g)].map(x => x[1]);
const elements = Object.fromEntries(ids.map(id => [id, {
  textContent: '',
  classList: {
    hidden: id === 'pm-devcoords-panel',
    add(name) { if (name === 'hidden') this.hidden = true; },
    remove(name) { if (name === 'hidden') this.hidden = false; }
  }
}]));
let handler;
vm.runInNewContext(script, {
  document: { getElementById: id => {
    assert(elements[id], 'missing element: ' + id);
    return elements[id];
  }},
  window: { addEventListener: (name, fn) => {
    assert.equal(name, 'message'); handler = fn;
  }}
});
handler({data:{action:'open'}});
assert.equal(elements['pm-devcoords-panel'].classList.hidden, false);
handler({data:{action:'update', vector3:'vector3(1, 2, 3)', vector4:'vector4(1, 2, 3, 90)', context:'Group / Row'}});
assert.equal(elements['pm-devcoords-vector3'].textContent, 'vector3(1, 2, 3)');
assert.equal(elements['pm-devcoords-vector4'].textContent, 'vector4(1, 2, 3, 90)');
assert.equal(elements['pm-devcoords-context'].textContent, 'Group / Row');
handler({data:{action:'close'}});
assert.equal(elements['pm-devcoords-panel'].classList.hidden, true);
console.log('PASS: NUI IDs, open, update, close');
