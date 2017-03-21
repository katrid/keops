
class Recognition
  constructor: ->
    @active = false

  init: ->
    rec = window.SpeechRecognition or window.webkitSpeechRecognition or window.mozSpeechRecognition or window.msSpeechRecognition or window.oSpeechRecognition
    rec = @recognition = new rec()
    rec.continuous = true
    rec.onresult = @onResult
    rec.onstart = => @active = true
    rec.onend = => @active = false
    return

  pause: ->
    @recognition.pause()

  resume: ->
    @recognition.resume()

  start: ->
    if not @recognition?
      @init()
    @recognition.start()

  stop: ->
    @recognition.stop()

  toggle: ->
    if @active
      @stop()
    else
      @start()

  onResult: (event) ->
    console.log(event)


class VoiceCommand extends Recognition
  constructor: ->
    super
    @commands = []

  onResult: (event) =>
    # Do command here
    res = event.results[event.results.length-1]
    cmd = res[0].transcript
    if cmd
      cmd = cmd.trim()
      console.log('do cmd', cmd)
      for obj in @commands
        if obj.name.toLocaleLowerCase() is cmd.toLocaleLowerCase()
          window.location.href = obj.href
          break
    return

  addCommands: (cmds) ->
    @commands = @commands.concat(cmds)


Katrid.Speech =
  Recognition: Recognition
  VoiceCommand: VoiceCommand

# Auto initialize voice command
Katrid.Speech.voiceCommand = new VoiceCommand()
if Katrid.Settings.Speech.enabled
  Katrid.Speech.voiceCommand.start()
