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
  let humanRestTime = "60";
  let restTime: number;
  $: restTime = safeParseInt(humanRestTime);
  let playIntervalSound = false;
  let humanIntervalTime = "30";
  let intervalTime: number;
  $: intervalTime = safeParseInt(humanIntervalTime);
  let playSounds = true;
  type DisplayStyle = "rectangle" | "circle";
  let timerStyle: DisplayStyle = "circle";

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
    let parsed = parseInt(input, 10);
    if (Number.isNaN(parsed)) {
      return 0;
    } else {
      return parsed;
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

  // Canvas Display
  let display: CanvasRenderingContext2D;
  let cw = 256;
  let ch = 256;
  let r = 117;

  // SVG Display
  let maxArcLength = 314;
  let progressValue = 0;
  $: progressValue = percentLeft * (maxArcLength / 100);
  let arc;
  $: if (arc) {
    arc.style.strokeDashoffset = progressValue;
  }

  onMount(() => {
    let canvas = document.getElementById("circleDisplay") as HTMLCanvasElement;
    canvas = makeHiPPICanvas(canvas);
    display = canvas.getContext("2d");
    arc = document.querySelector("#progressArc");
    renderDisplay(100);
  });

  function renderDisplay(percent: number) {
    let startingPoint = 4.72; // top of circle is 1.5π
    let endingPoint = (percent / 100) * 2 * Math.PI; // draw clockwise to percent of total circle

    // Start from scratch when this function is called
    display.clearRect(0, 0, display.canvas.width, display.canvas.height);
    display.lineWidth = 20;
    display.textAlign = "center";
    display.font = "bold 4em sans-serif";
    display.fillStyle = "#000";

    // render time left in the middle
    display.fillText(formatTime(timeLeft), cw / 2, ch / 2 + 20); //fillText(text,x,y);

    // render the background ring behind the progress ring
    display.beginPath();
    display.arc(cw / 2, ch / 2, r, 0, 2 * Math.PI); //arc(x,y,radius,start,stop)
    display.strokeStyle = "#e5f6f8";
    display.stroke(); // needed to fill the arc path we just made

    // render the progress ring around the outside by cutting out an
    // arc representing a path to hide the circle below it
    display.beginPath();
    display.arc(cw / 2, ch / 2, r, startingPoint, startingPoint + endingPoint); //arc(x,y,radius,start,stop)
    display.strokeStyle = "#00ff43";
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
  hr {
    @apply block my-4;
  }
  #circleDisplay {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    z-index: 9;
  }
  #progressArc {
    stroke-dasharray: 314;
    stroke-dashoffset: 0;
    transform-origin: 50px 50px;
    transform: rotate(-90deg) scale(-1);
  }
  svg text {
    @apply font-bold;
  }
</style>

<div class="flex flex-wrap">
  <div
    id="boxingTimer"
    class="w-72 border border-purple-700 rounded-lg pb-4 mx-auto my-4">
    <p class="text-2xl">Boxing Timer</p>

    <div class="text flex justify-evenly space-x-4 mx-auto">
      <div>Round: {completedRounds + 1}</div>
      <div>State: {currentState}</div>
    </div>

    <div
      class="h-24 w-64 mt-4 bg-gray-300 mx-auto text-6xl flex items-center
      justify-center font-bold rounded"
      class:hidden={!(timerStyle === 'rectangle')}>
      {formatTime(timeLeft)}
    </div>

    <div
      class="relative h-64 w-64 mx-auto flex items-center justify-center"
      class:hidden={!(timerStyle === 'circle')}>
      <canvas height={ch} width={cw} id="circleDisplay" />
    </div>

    <div
      class="relative h-64 w-64 mx-auto flex items-center justify-center"
      class:hidden={!(timerStyle === 'circle')}>
      <svg viewBox="0 0 100 100">
        <!-- <g id="grid" stroke="green" stroke-width=".2">
          <path d="M0 10 H100" />
          <path d="M0 20 H100" />
          <path d="M0 30 H100" />
          <path d="M0 40 H100" />
          <path d="M0 50 H100" stroke-width="1" />
          <path d="M0 60 H100" />
          <path d="M0 70 H100" />
          <path d="M0 80 H100" />
          <path d="M0 90 H100" />

          <path d="M10 0 V100" />
          <path d="M20 0 V100" />
          <path d="M30 0 V100" />
          <path d="M40 0 V100" />
          <path d="M50 0 V100" stroke-width="1" />
          <path d="M60 0 V100" />
          <path d="M70 0 V100" />
          <path d="M80 0 V100" />
          <path d="M90 0 V100" />
        </g> -->

        <!-- A rx ry x-axis-rotation large-arc-flag sweep-flag x y -->
        <!-- Define a path so we can clip it later.  We do this to simulate an
          inner stroke, since SVG doesn't support that natively yet.
          Double the stoke size, and then clip to the outside, and your stroke is
          now effectively inner. -->
        <defs>
          <path id="circle" d="M0,50 A50,50 0 1 0 0,49.999" />
          <clipPath id="clip">
            <use xlink:href="#circle" />
          </clipPath>
        </defs>

        <use
          xlink:href="#circle"
          id="backgroundArc"
          stroke="blue"
          stroke-width="18"
          fill="none"
          clip-path="url(#clip)" />
        <use
          xlink:href="#circle"
          id="progressArc"
          stroke="#e5f6f8"
          stroke-width="20"
          fill="none"
          clip-path="url(#clip)" />
        <text
          id="svgTime"
          class="font-bold text-2xl"
          x="50%"
          y="59%"
          text-anchor="middle"
          alignment-baseline="middle">
          {formatTime(timeLeft)}
        </text>
      </svg>
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

    <div id="restTimeControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={takeRestRound} />
      Rest Time:
      <input
        class="ml-2 mr-1 w-8 rounded text-center"
        bind:value={humanRestTime} />
      seconds
    </div>

    <hr />

    <div id="soundControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={playSounds} />
      Play Round Begin/End Sounds
    </div>

    <div id="intervalControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={playIntervalSound} />
      Interval Sound:
      <input
        id="interval"
        class="ml-2 mr-1 w-8 rounded text-center"
        bind:value={humanIntervalTime} />
      seconds
    </div>

    <hr />

    <div id="displayStyle" class="mt-4 mx-4">
      Timer Display Style
      <div class="mt-2 ml-4">
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
