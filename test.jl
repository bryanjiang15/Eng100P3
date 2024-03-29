#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("instruments.jl")
const start_times = Dict{UInt32, UInt32}()

playNote = false;
index = 1;
freql = [523.25, 554.37, 587.33, 622.25, 659.26, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77]

w = GtkWindow("Key Press/Release Example")

id1 = signal_connect(w, "key-press-event") do widget, event
    k = event.keyval
    if k ∉ keys(start_times)
        start_times[k] = event.time # save the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
        global playNote = true;
        global index = k%length(freql) + 1
    else
        println(playNote)
    end
end

id2 = signal_connect(w, "key-release-event") do widget, event
    k = event.keyval
    start_time = pop!(start_times, k) # remove the key from the dictionary
    duration = event.time - start_time # key press duration in milliseconds
    println("You released key ", k, " after time ", duration, " msec.")
    global playNote = false;
end

stream = PortAudioStream(0, 1; warn_xruns=false)

song = zeros(round(Int, 20 * stream.sample_rate))

function play_tone(stream, freq::Real, duration::Real; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    
    while current < duration*S
        amplitude = 0
        freq1 = freql[index];
        if(playNote)
          amplitude = 0.7
        end
        x = amplitude * getNote(index, 1)
        global song[current:current+buf_size-1] = x[1:buf_size];
        write(stream, x)
        current += buf_size
    end
    nothing
end

play_tone(stream, 440, 10)
soundsc(song, stream.sample_rate)
# PortAudioStream(0, 1; 44100) do stream
#     write(stream, bassDrum())
#   end

