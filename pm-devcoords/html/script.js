const panel = document.getElementById('pm-devcoords-panel');
window.addEventListener('message', ({ data = {} }) => {
    if (data.action === 'open') panel.classList.remove('hidden');
    if (data.action === 'close') panel.classList.add('hidden');
    if (data.action === 'update') {
        document.getElementById('pm-devcoords-vector3').textContent = data.vector3;
        document.getElementById('pm-devcoords-vector4').textContent = data.vector4;
        document.getElementById('pm-devcoords-context').textContent = data.context || 'No collection selected';
    }
});
