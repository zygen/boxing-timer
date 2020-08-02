<script lang="typescript">
  import { onMount } from "svelte";

  let roundBeginSound = new Audio(`BoxingCircuitBeginRound.mp3`);
  let roundEndSound = new Audio(`BoxingCircuitEndRound.mp3`);
  let intervalSound = new Audio(`BoxingCircuitBeginRound.mp3`);

  // Configurable
  let humanRoundTime = "3:00";
  let roundTime = parseRoundTime(humanRoundTime);
  $: roundTime = parseRoundTime(humanRoundTime);
  $: percentLeft = (timeLeft / roundTime) * 100;
  $: if (document.getElementById("circleDisplay")) {
    renderDisplay(percentLeft);
  }
  let takeRestRound = true;
  let restTime = 60;
  let playIntervalSound = false;
  let intervalTime = 30;
  let playSounds = true;
  type DisplayStyle = "rectangle" | "circle";
  let timerStyle: DisplayStyle = "rectangle";

  // State
  type State = "ready" | "working" | "stopped" | "resting";
  let timeLeft = roundTime;
  let timer: number;
  let currentState: State = "ready";
  let completedRounds = 0;

  function transition(state: State, time: number) {
    clearInterval(timer);
    setTimeout(() => {
      currentState = state;
      timeLeft = time;
    }, 0);
  }

  function startTimer() {
    if (currentState !== "working") {
      timer = setInterval(() => {
        if (timeLeft % intervalTime === 1 && timeLeft !== 1) {
          if (playIntervalSound) {
            intervalSound.play();
          }
        } else if (timeLeft === 0) {
          finishRound();
        }
        timeLeft -= 1;
      }, 1000);
    }
    setTimeout(() => {
      currentState = "working";
      if (playSounds) {
        roundBeginSound.play();
      }
    }, 0);
  }

  function finishRound() {
    if (playSounds) {
      roundEndSound.play();
    }
    completedRounds += 1;
    if (takeRestRound) {
      transition("resting", restTime);
      rest();
    } else {
      transition("ready", roundTime);
      startTimer();
    }
  }

  function stopTimer() {
    clearInterval(timer);
    currentState = "stopped";
  }

  function resetTimer() {
    completedRounds = 0;
    transition("ready", roundTime);
  }

  function rest() {
    timer = setInterval(() => {
      if (timeLeft === 0) {
        transition("ready", roundTime);
        startTimer();
      }
      timeLeft -= 1;
    }, 1000);
  }

  function formatTime(timeInSeconds: number): string {
    const minutes = Math.floor(timeInSeconds / 60);
    const remainingSeconds = timeInSeconds % 60;
    return `${pad0(minutes)}:${pad0(remainingSeconds)}`;
  }

  function safeParseInt(input: string): number {
    let result = parseInt(input);
    if (Number.isNaN(result)) {
      return 0;
    } else {
      return result;
    }
  }

  function parseRoundTime(input: string): number {
    let [m, s] = input.split(":");
    let minutes: number = safeParseInt(m);
    let seconds: number = Math.min(safeParseInt(s), 60);
    return minutes * 60 + seconds;
  }

  function pad0(num: number): string {
    return num.toString().padStart(2, "0");
  }

  let display: CanvasRenderingContext2D;

  onMount(() => {
    let canvas = document.getElementById("circleDisplay") as HTMLCanvasElement;
    canvas = makeHiPPICanvas(canvas);
    display = canvas.getContext("2d");
    renderDisplay(100);
  });

  function renderDisplay(percent: number) {
    let startingPoint = 4.72;
    let endingPoint = (percent / 100) * 2 * Math.PI * 10;

    // Start from scratch when this function is called
    display.clearRect(0, 0, display.canvas.width, display.canvas.height);
    display.lineWidth = 15;
    display.strokeStyle = "#00ff43";
    display.textAlign = "center";
    display.font = "bold 50px sans-serif";
    display.fillStyle = "#000";

    // render time left in the middle
    display.fillText(formatTime(timeLeft), 100, 115); //fillText(text,x,y);

    // render the progress ring around the outside
    display.beginPath();
    display.arc(100, 100, 90, startingPoint, startingPoint + endingPoint / 10); //arc(x,y,radius,start,stop)
    display.stroke(); // needed to fill the arc path we just made
  }

  var PIXEL_RATIO = (function () {
    let ctx: any = document.createElement("canvas").getContext("2d");
    let dpr = window.devicePixelRatio || 1;
    let bsr =
      ctx.webkitBackingStorePixelRatio ||
      ctx.mozBackingStorePixelRatio ||
      ctx.msBackingStorePixelRatio ||
      ctx.oBackingStorePixelRatio ||
      ctx.backingStorePixelRatio ||
      1;
    return dpr / bsr;
  })();

  function makeHiPPICanvas(canvas: HTMLCanvasElement) {
    let w = canvas.width;
    let h = canvas.height;
    canvas.width = w * PIXEL_RATIO;
    canvas.height = h * PIXEL_RATIO;
    canvas.style.width = w + "px";
    canvas.style.height = h + "px";
    canvas.getContext("2d").setTransform(PIXEL_RATIO, 0, 0, PIXEL_RATIO, 0, 0);
    return canvas;
  }
</script>

<style lang="postcss">
  p {
    @apply mt-4;
  }
  button {
    @apply py-2 px-4 rounded;
  }
  #circleDisplay {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 9;
  }
  #circle1 {
    height: 165px;
    width: 165px;
    background-color: #fff;
    border-radius: 50%;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 1;
  }
  #circle2 {
    height: 196px;
    width: 196px;
    background-color: #e5f6f8;
    border-radius: 50%;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: -1;
  }
</style>

<div class="flex flex-wrap">
  <div
    id="boxingTimer"
    class="w-72 border border-purple-700 rounded-lg pb-4 mx-auto my-4">
    <p class="text-2xl">Boxing Timer</p>

    <p class="text">State: {currentState}</p>

    <div
      class="h-24 w-64 mt-4 bg-gray-300 mx-auto text-6xl flex items-center
      justify-center font-bold rounded"
      class:hidden={!(timerStyle === 'rectangle')}>
      {formatTime(timeLeft)}
    </div>

    <div
      class="relative h-56 w-64 -mb-4 mx-auto flex items-center justify-center"
      class:hidden={!(timerStyle === 'circle')}>
      <div id="circle1" />
      <div id="circle2" />
      <canvas height="200" width="200" id="circleDisplay" />
    </div>

    <div id="timerControls" class="mt-4 mx-4 flex justify-between">
      <button
        class="bg-green-200"
        on:click={startTimer}
        disabled={!(currentState === 'ready' || currentState === 'stopped')}>
        start
      </button>
      <button
        class="bg-yellow-200"
        on:click={stopTimer}
        disabled={!(currentState === 'working' || currentState === 'resting')}>
        stop
      </button>
      <button class="bg-red-200" on:click={resetTimer}>reset</button>
    </div>
  </div>

  <div
    id="boxingTimerSettings"
    class="w-72 border border-purple-700 rounded-lg pb-4 align-top text-left
    mx-auto my-4">

    <p class="text-2xl text-center">Settings</p>

    <div id="roundTimeControls" class="mt-4 mx-4">
      Round Time:
      <input
        id="interval"
        class="ml-2 mr-1 w-16 rounded text-center"
        bind:value={humanRoundTime} />
    </div>

    <div id="intervalControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={playSounds} />
      Play Round Begin/End Sounds
    </div>

    <div id="restTimeControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={takeRestRound} />
      Rest Time:
      <input class="ml-2 mr-1 w-8 rounded text-center" bind:value={restTime} />
      seconds
    </div>

    <div id="intervalControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={playIntervalSound} />
      Interval Sound:
      <input
        id="interval"
        class="ml-2 mr-1 w-8 rounded text-center"
        bind:value={intervalTime} />
      seconds
    </div>

    <div id="displayStyle" class="mt-4 mx-4">
      <span class="pb-2">Timer Display Style</span>
      <div class="ml-4">
        <label>
          <input type="radio" bind:group={timerStyle} value={'rectangle'} />
          Rectangle
        </label>
        <label>
          <input type="radio" bind:group={timerStyle} value={'circle'} />
          Circle
        </label>
      </div>
    </div>
  </div>
</div>

<p class="mb-4">
  Completed Rounds: {completedRounds} ({formatTime(completedRounds * roundTime)})
</p>
