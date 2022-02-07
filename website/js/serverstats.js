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
  d3.json('https://play.jarno.ca/monitoring/all').then(function(data){
    updateGraph(data, '#memgraph', 'mem', 'm');
    updateGraph(data, '#cpugraph', 'cpu', 'c');
  });
}
