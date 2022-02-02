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
    socket.send('help');
  });

  // Listen for messages
  socket.addEventListener('message', function (event) {
    const xonotic_output = document.getElementById('xonotic_output');
    let line = document.createElement('p')
    line.innerHTML = convertTerminalCodeToHtml(event.data);
    xonotic_output.prepend(line);
  });
}

function sendHello() {
  socket.send('Hello');
}

// Shell command can have control codes. Some of these mean colours.
function convertTerminalCodeToHtml(line) {
  let htmlline = "";
  let open_spans = 0;
  for(let i = 0; i < line.length; i++) {
    if(line[i] == '\033') {
      let code = line[++i]
      if(code == '[') {
        // This means it's a colour
        let colour_code = "";
        for(i++; i < line.length && line[i] != 'm'; i++) {
          colour_code += line[i];
        }
        colour_code = parseInt(colour_code);
        if(colour_code === 0) {
          for(let i = 0; i < open_spans; i++) {
            htmlline += "</span>";
          }
        }
        else if(colour_code >= 30 && colour_code <= 37) {
          htmlline += '<span class="TERM_FOREGROUND_'+(colour_code-30)+'">';
          open_spans++;
        }
        else if(colour_code >= 90 && colour_code <= 97) {
          htmlline += '<span class="TERM_FOREGROUND_'+(colour_code-90)+'_INTENSE">';
          open_spans++;
        }
      }
    }
    else if(line[i] == '<') {
      htmlline += "&lt;"
    }
    else if(line[i] == '>') {
      htmlline += "&gt;"
    }
    else if(line[i] == '&') {
      htmlline += "&amp;"
    }
    else {
      htmlline += line[i];
    }
  }

  for(let i = 0; i < open_spans; i++) {
    htmlline += "</span>";
  }

  return htmlline
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', xonotic_init);
} else {
  xonotic_init();
}
