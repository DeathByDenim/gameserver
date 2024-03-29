// Parse the Xonotic score log format and return a JSON
// The returned data contains data for the individual
// rounds as well as totals
async function xonoticGetScores() {
    const data = await fetch("xonscore.txt");
    const text = await data.text();

    let stats = {
        rounds: [],
        totals: []
    };
    let map_name = "[unknown]";
    let duration_in_seconds = 0;
    let labels = [];
    let round_stats = [];
    text.split("\n").forEach((row) => {
        const fields = row.split(":");
        if(fields.length > 1) {
            const verb = fields[1]
            switch(verb) {
                case "scores":
                    map_name = fields[2];
                    duration_in_seconds = fields[3];
                    break;
                case "labels":
                    if(fields[2] === "player") {
                        labels = fields[3].split(",");
                    }
                    break;
                case "player":
                    if(fields[2] === "see-labels") {
                        if(fields[5] === "spectator") {
                            break;
                        }
                        const split_fields = fields[3].split(",");

                        // Filter out the custom colours in names
                        const player_name = fields[6]
                            .replace(/\^x.../g, "")
                            .replace(/\^\d/g, "");
                        let player_stats = {name: player_name};
                        for(let i = 0; i < labels.length; i++) {
                            if(labels[i] != "") {
                            player_stats[labels[i]] = split_fields[i]
                            }
                        }
                        round_stats.push(player_stats);
                    }
                    break;
                case "end":
                    if(round_stats.length > 0) {
                        round_stats = round_stats.sort((a,b) => +a["score!!"] < +b["score!!"]);
                        stats.rounds.push({
                            map_name: map_name,
                            duration_in_seconds: duration_in_seconds,
                            stats: round_stats
                        })
                    }
                    round_stats = [];
                    labels = [];
                    duration_in_seconds = 0;
                    map_name = "";
                    break;
            }
        }
    })

    let final = {};
    stats.rounds.forEach((map) => {
            map.stats.forEach((stat) => {
                if(stat.name in final) {
                    final[stat.name] += +stat["score!!"]
                }
                else {
                    final[stat.name] = +stat["score!!"]
                }
            });
        });

    Object.keys(final).forEach(name => {
        stats.totals.push({
            name: name,
            score: final[name]
        })
    });
    stats.totals = stats.totals.sort((a,b) => a.score < b.score);

    return stats;
}

function xonoticScoreUpdate() {
    xonoticGetScores().then((data) => {
        d3.select("#xonotic-ranking")
            .selectAll("li")
            .data(data.totals)
            .join("li")
            .text(d => d.name + " (" + d.score + ")");

        let tables = d3.select("#xonotic-results")
            .selectAll("table")
            .data(data.rounds)
            .join(
                (enter) => {
                    let table = enter.append("table");
                    let thead = table.append("thead");
                    thead.append("tr")
                    .append("th")
                    .attr("colspan", 5)
                    .text((d) => "Map name: " + d.map_name);
                    let headerrows = thead.append("tr");

                    ["Name", "Score", "Kills", "Deaths", "Suicides"].forEach((col) => {
                    headerrows.append("th").text(col);
                    })

                    table.append("tbody");
                    return table;
                },
                (update) => {
                    let u = update;
                    u.select("th").text((d) => "Map name: " + d.map_name);
                    return u;
                },
                (exit) => exit.remove()
            )
            .classed("table", true);

        let tbodies = tables.select('tbody');
        tbodies.selectAll("tr")
            .data((d) => d.stats)
            .join("tr")
            .selectAll("td")
            .data((d) => ["name", "score!!", "kills", "deaths<", "suicides<"].map((col) => d[col]))
            .join("td")
                .text((d) => d);
    });
}
