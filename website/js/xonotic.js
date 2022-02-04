function xonotic_init() {
  const command_form = document.getElementById('xonotic_form');
  const command_input = document.getElementById('xonotic_command');

  // Connect the command submission
  if(command_input && command_form) {
    command_form.addEventListener('submit', function(){
      let line = document.createElement('p')
      line.innerHTML = '<span class="TERM_FOREGROUND_7_INTENSE">$ </span>' + command_input.value;
      xonotic_output.prepend(line);
      socket.send(command_input.value);
      command_input.value = "";
    });
  }

  // Create WebSocket connection.
  const socket = new WebSocket("ws://192.168.122.229/xonotic")

  // Connection opened
  socket.addEventListener('open', function (event) {
    socket.send('who');
  });

  socket.addEventListener('error', function (event) {
    console.error(event);
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
    const xonotic_output = document.getElementById('xonotic_output');
    let line = document.createElement('p')
    line.innerHTML = convertTerminalCodeToHtml(event.data);
    xonotic_output.prepend(line);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', xonotic_init);
} else {
  xonotic_init();
}
