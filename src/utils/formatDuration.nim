import std/times

proc formatDuration*(duration: Duration): string =
    let dt = initTime(0, 0).utc + duration
    return dt.format("mm:ss:fff")