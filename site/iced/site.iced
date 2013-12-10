$ ->
  if window.location.href.indexOf('now_in_python.html') is -1
    window.location = './triplesec_now_in_python.html'

  textarea_auto = (ta) ->
    ta.style.overflow = 'hidden'
    ta.style.height   = 0
    ta.style.height   = "#{25 + Math.min(600,Math.max(ta.scrollHeight, 50))}px"

  input_change = ->
    textarea_auto $('#demo-input-data')[0]
    v = $('#demo-input-data').val()
    k = $('#demo-input-key').val()
    $('.btn-encrypt, .btn-decrypt').prop('disabled', true)
    if v and v.length and k and k.length
      $('.btn-encrypt').prop('disabled', false)
      if (v.match /// ^ [a-f0-9]+ $///i ) and not (v.length % 2)
        $('.btn-decrypt').prop('disabled', false)

  progress = []

  reset_progress = (msg) ->
    progress = []
    $("#progress-summary").html (msg or '')

  progress_hook = (p) ->
    if (progress.length) and (progress[progress.length-1].what is p.what)
      progress[progress.length-1] = p
    else
      progress.push p
    h = ""
    h += "<li>#{pr.what} #{pr.i}/#{pr.total}</li>" for pr in progress
    $("#progress-summary").html h

  $('#demo-input-data').on 'change',  -> input_change()
  $('#demo-input-data').on 'keyup',   -> input_change()
  $('#demo-input-key').on  'change',  -> input_change()
  $('#demo-input-key').on  'keyup',   -> input_change()


  $('.btn-encrypt').on 'click', =>
    reset_progress()
    $('.btn-encrypt, .btn-decrypt').prop('disabled', true)
    data   = new triplesec.Buffer $('#demo-input-data').val()
    key    = new triplesec.Buffer $('#demo-input-key').val()
    await triplesec.encrypt {
      data: data
      key:  key
      rng:  triplesec.rng
      progress_hook: progress_hook
      version: 3
    }, defer err, out
    await setTimeout defer(), 5
    if err
      reset_progress "<li>#{err}</li>"
    else
      hex = out.toString 'hex'          
      $("#demo-input-data").val hex
      textarea_auto $("#demo-input-data")[0]
    input_change()

  $('.btn-decrypt').on 'click', =>
    reset_progress()
    $('.btn-encrypt, .btn-decrypt').prop('disabled', true)
    data   = new triplesec.Buffer $('#demo-input-data').val(), 'hex'
    key    = new triplesec.Buffer $('#demo-input-key').val()
    await triplesec.decrypt {
      data: data
      key:  key
      progress_hook: progress_hook
    }, defer err, out
    await setTimeout defer(), 5
    if err
      reset_progress "<li>#{err}</li>"
    else
      txt = out.toString()
      $("#demo-input-data").val txt
      textarea_auto $("#demo-input-data")[0]
    input_change()

  textarea_auto $("#demo-input-data")[0]