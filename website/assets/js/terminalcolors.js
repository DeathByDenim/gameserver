// Collection of scripts to deploy a server hosting several open-source games
// Copyright (C) 2022  Jarno van der Kolk
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// Shell command can have control codes. Some of these mean colours.
function convertTerminalCodeToHtml(line) {
  let htmlline = "";
  let open_spans = 0;
  for(let i = 0; i < line.length; i++) {
    if(line[i] == '\033') {
      let code = line[++i]
      if(code == '[') {
        // This means it's a colour
        while(i < line.length && line[i] != 'm') {
          let colour_code = "";
          for(i++; i < line.length && line[i] != 'm' && line[i] != ';'; i++) {
            colour_code += line[i];
          }
          colour_code = parseInt(colour_code);
          if(colour_code === 0) {
            for(let i = 0; i < open_spans; i++) {
              htmlline += "</span>";
            }
            open_spans = 0;
          }
          if(colour_code === 1) {
            htmlline += '<span class="TERM_FOREGROUND_BOLD">';
            open_spans++;
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

// Shell command can have control codes. Some of these mean colours.
function convertDaemonedCodeToHtml(line) {
  let htmlline = "";
  let open_spans = 0;
  for(let i = 0; i < line.length; i++) {
    if(line[i] == '^') {
      let code = line[++i]
      for(let i = 0; i < open_spans; i++) {
        htmlline += "</span>";
      }
      open_spans = 0;

      if(code == 'N') {
        htmlline += '<span class="TERM_FOREGROUND_BOLD">';
        open_spans++;
      }
      else {
        let colour_code = parseInt(code);
        if(colour_code >= 0) {
          htmlline += '<span class="TERM_FOREGROUND_'+colour_code+'">';
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
