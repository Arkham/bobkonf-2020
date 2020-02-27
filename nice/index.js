let app = Elm.Main.init({ node: document.querySelector('main') });

app.ports.sendRingtone.subscribe(function(data) {
  let context = new AudioContext();

  data.reduce(function(now, elem) {
    oscillator = context.createOscillator();
    oscillator.connect(context.destination);
    oscillator.setPeriodicWave(wave);
    oscillator.frequency.value = elem.frequency;
    oscillator.start(context.currentTime + now);
    oscillator.stop(context.currentTime + now + elem.duration);
    return(now + elem.duration);
  }, 0);
});
