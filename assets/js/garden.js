var garden = {
    current_segment: 0,
    current_bloc: 0,
    setSegment: function(sid) {
        this.current_segment = sid;
        $.get("/" + this.current_segment)
            .success(function(data) {
                console.log("Segment fetched: " + data);
                $("#show_segment").html(data);
            });
    },
    setBloc: function(bid) {
        this.current_bloc = bid;
        console.log("Bloc: " + bid);
        $.get("/" + this.current_segment + "/bloc/" + this.current_bloc)
            .success(function(data) {
                console.log("Bloc fetched: " + data);
                $("#show_bloc").html(data);
            });
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