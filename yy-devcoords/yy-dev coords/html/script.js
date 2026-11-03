const panel = document.getElementById('dc-panel');
window.addEventListener('message', ({ data = {} }) => {
    if (data.action === 'open') panel.classList.remove('hidden');
    if (data.action === 'close') panel.classList.add('hidden');
    if (data.action === 'update') {
        document.getElementById('dc-vec3').textContent = data.vec3;
        document.getElementById('dc-vec4').textContent = data.vec4;
        document.getElementById('dc-context').textContent = data.context || 'No collection selected';
    }
});
