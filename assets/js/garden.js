var garden = {
    current_segment: 0,
    current_bloc: 0,
    setSegment: function(sid) {
        this.current_segment = sid;
        $.get("/" + this.current_segment)
            .success(function(data) {
                $("#show_segment").html(data);
            });
    },
    setBloc: function(bid) {
        this.current_bloc = bid;
        $.get("/" + this.current_segment + "/bloc/" + this.current_bloc)
            .success(function(data) {
                $("#show_bloc").html(data);
            });
    },
    current_locked_segment: 0,
    current_locked_bloc: 0,
    setLockedBloc: function(sid, bid) {
        $(".bloc_active[data-segment='" + this.current_locked_segment + "'][data-bloc='" + this.current_locked_bloc + "']").toggleClass("bloc_locked");

        this.current_locked_segment = sid;
        this.current_locked_bloc = bid;
        $.get("/" + this.current_locked_segment + "/bloc/" + this.current_locked_bloc)
            .success(function(data) {
                $("#show_locked_bloc").html(data);
            });
        $(".bloc_active[data-segment='" + this.current_locked_segment + "'][data-bloc='" + this.current_locked_bloc + "']").toggleClass("bloc_locked");
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