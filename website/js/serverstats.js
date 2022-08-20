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
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

let heightScale = d3.scaleLinear()
  .domain([0,100])
  .range([100,0]);
let timeScale = d3.scaleLinear()
  .domain([0,60])
  .range([5,305]);

function updateGraph(data, svgid, property_class, property) {
  d3.select(svgid)
    .selectAll('line')
    .data(data, function(d) {return d.t})
    .join(
      function(enter) {
        return enter
          .append('line')
          .attr('x1', function(d,i){return timeScale(i)})
          .attr('x2', function(d,i){return timeScale(i)})
          .attr('y1', function(d,i){return heightScale(0)})
          .attr('y2', 100)
          .attr('class', property_class);
      },
      function(update) {
        return update
      },
      function(exit) {
        return exit.remove();
      }
    )
    .transition()
    .ease(d3.easeLinear)
    .duration(5000)
    .attr('x1', function(d,i){return timeScale(i-1)})
    .attr('x2', function(d,i){return timeScale(i-1)})
    .attr('y1', function(d,i){return heightScale(d[property])})
}

function update() {
  d3.json('https://DOMAINNAME/monitoring/all').then(function(data){
    updateGraph(data, '#memgraph', 'mem', 'm');
    updateGraph(data, '#cpugraph', 'cpu', 'c');
  });
}
