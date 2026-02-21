window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.type === "update") {
        $("#speed").text(Math.floor(data.speed));
        $("#zero60").text(data.zero60.toFixed(2) + "s");
        $("#hundred200").text(data.hundred200.toFixed(2) + "s");
        $("#best").text(data.best.toFixed(2) + "s");
        $("#status").text(data.status);

        // Update the ring
        const circle = document.getElementById('speed-arc');
        const circumference = 50 * 2 * Math.PI;
        circle.style.strokeDasharray = `${circumference} ${circumference}`;
        const offset = circumference - (Math.min(data.speed, 200) / 200) * circumference;
        circle.style.strokeDashoffset = offset;
    }

    if (data.type === "show") {
        $("#vbox-container").show();
    } else if (data.type === "hide") {
        $("#vbox-container").hide();
    }
});