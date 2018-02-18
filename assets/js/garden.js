let garden = {
    current_segment: 0,
    current_bloc: 0,
    setSegment: function(sid) {
        this.current_segment = sid;
        $.get("/info/segment/" + this.current_segment)
            .success(function(data) {
                $("#show_segment").html(data);
            });
    },
    setBloc: function(bid) {
        this.current_bloc = bid;
        $.get("/info/segment/" + this.current_segment + "/bloc/" + this.current_bloc)
            .success(function(data) {
                $("#show_bloc").html(data);
            });
    },
    current_locked_segment: -1,
    current_locked_bloc: -1,
    setLockedBloc: function(sid, bid) {
        if (this.currnet_locked_bloc != -1) {
            $(".bloc_active[data-segment='" + this.current_locked_segment + "'][data-bloc='" + this.current_locked_bloc + "']").toggleClass("bloc_locked");
        }

        this.current_locked_segment = sid;
        this.current_locked_bloc = bid;
        $.get("/info/segment/" + this.current_locked_segment + "/bloc/" + this.current_locked_bloc)
            .success(function(data) {
                $("#show_locked_bloc").html(data);
            });
        console.log('Locking ' + this.current_locked_segment + 'x' + this.current_locked_bloc);
        $(".bloc_active[data-segment='" + this.current_locked_segment + "'][data-bloc='" + this.current_locked_bloc + "']").toggleClass("bloc_locked");
    },
    current_plant_id: -1,
    current_plant_projection_id: -1,
    setPlant: function(plant_id) {
        if (plant_id != this.current_plant_id) {
            console.log("About to seek plant: " + plant_id);
            this.current_plant_id = plant_id;
            $.get("/info/plant/" + this.current_plant_id)
                .success(function(data) {
                    $("#show_plant").html(data);
                });
        }
    },
    setProjection: function(plant_id) {
        if (plant_id != this.current_plant_id) {
            console.log("About to seek plant projection: " + plant_id);
            this.current_plant_projection_id = plant_id;
            $.get("/info/projection/" + this.current_plant_projection_id)
                .success(function(data) {
                    $("#show_projection_plant").html(data);
                });
        }
    }
}


$(".bloc_active").hover(function() {
    // mouse in   
    var segment = $(this).data("segment");
    var bloc = $(this).data("bloc");

    garden.setSegment(segment);
    garden.setBloc(bloc);
}, function() {
    // mouse out
});

$(".bloc_active").click(function() {
    // mouse in   
    var segment = $(this).data("segment");
    var bloc = $(this).data("bloc");

    garden.setLockedBloc(segment, bloc);
});

$(".segment_active[data-plant-id]").click(function() {
    // on click on a segment with a plant. 
    var plant_id = $(this).data("plant-id");
    garden.setPlant(plant_id);
    garden.setProjection(plant_id);
})

