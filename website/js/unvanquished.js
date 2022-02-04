function unvanquished_init() {
  const command_form = document.getElementById('unvanquished_form');
  const command_input = document.getElementById('unvanquished_command');

  // Connect the command submission
  if(command_input && command_form) {
    command_form.addEventListener('submit', function(){
      let line = document.createElement('p')
      line.innerHTML = '<span class="TERM_FOREGROUND_7_INTENSE">$ </span>' + command_input.value;
      unvanquished_output.prepend(line);
      socket.send(command_input.value);
      command_input.value = "";
    });
  }

  // Create WebSocket connection.
  const socket = new WebSocket("ws://192.168.122.229/unvanquished")

  // Connection opened
  socket.addEventListener('open', function (event) {
    socket.send('/status');
  });

  socket.addEventListener('error', function (event) {
    console.error(event);
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
    const unvanquished_output = document.getElementById('unvanquished_output');
    let line = document.createElement('p')
    line.innerHTML = convertDaemonedCodeToHtml(event.data);
    unvanquished_output.prepend(line);
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', unvanquished_init);
} else {
  unvanquished_init();
}
