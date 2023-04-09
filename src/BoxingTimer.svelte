<script lang="ts">
  import { onMount } from "svelte";

  // Configurable
  let humanRoundTime = "3:00";
  let humanIntervalTime = "30";
  let humanRestTime = "60";
  let takeRestRound = true;
  let playSounds = false;
  let playIntervalSound = false;

  // Derived
  let roundTime = parseRoundTime(humanRoundTime);
  $: roundTime = parseRoundTime(humanRoundTime);
  let restTime = safeParseInt(humanRestTime);
  $: restTime = safeParseInt(humanRestTime);
  let intervalTime = safeParseInt(humanIntervalTime);
  $: intervalTime = safeParseInt(humanIntervalTime);

  $: percentLeft = (timeLeft / roundTime) * 100;

  // Sound
  let roundBeginSound = new Audio(`BoxingCircuitBeginRound.mp3`);
  let roundEndSound = new Audio(`BoxingCircuitEndRound.mp3`);
  let intervalSound = new Audio(`BoxingCircuitBeginRound.mp3`);

  //
  // Core State Machine
  //

  type State =
    | "ready"
    | "start"
    | "startRound"
    | "working"
    | "resting"
    | "finishRound"
    | "stopped"
    | "reset";

  type StateMachineEntry = {
    onEnter?: () => void;
    onExit?: () => void;
  };

  type StateMachine = Record<State, StateMachineEntry> & {
    transition: (state: State) => void;
  };

  let timeLeft = roundTime;
  let timer: NodeJS.Timeout;
  let currentState: State = "ready";
  let completedRounds = 0;

  const stateMachine: StateMachine = {
    ready: {
      onEnter: () => {
        timeLeft = roundTime;
      },
    },
    start: {
      onEnter: () => {
        stateMachine.transition("working");
      },
    },
    startRound: {
      onEnter: () => {
        timeLeft = roundTime;
        stateMachine.transition("working");
      },
    },
    working: {
      onEnter: () => {
        if (playSounds) {
          roundBeginSound.play();
        }
        timer = startInterval(() => {
          timeLeft -= 1;
          if (timeLeft % intervalTime === 0 && timeLeft !== 0) {
            if (playIntervalSound) {
              intervalSound.play();
            }
          } else if (timeLeft === 0) {
            stateMachine.transition("finishRound");
          }
        });
      },
      onExit: () => {
        clearInterval(timer);
      },
    },
    finishRound: {
      onEnter: () => {
        if (playSounds) {
          roundEndSound.play();
        }
        completedRounds += 1;
        if (takeRestRound) {
          stateMachine.transition("resting");
        } else {
          stateMachine.transition("ready");
        }
      },
    },
    resting: {
      onEnter: () => {
        timeLeft = restTime;
        timer = setInterval(() => {
          timeLeft -= 1;
          if (timeLeft === 0) {
            stateMachine.transition("startRound");
          }
        }, 1000);
      },
      onExit: () => {
        clearInterval(timer);
      },
    },
    stopped: {
      onEnter: () => {
        clearInterval(timer);
      },
    },
    reset: {
      onEnter: () => {
        completedRounds = 0;
        stateMachine.transition("ready");
      },
    },
    transition: (state: State) => {
      const currentStateMachine = stateMachine[
        currentState
      ] as StateMachineEntry;
      const newStateMachine = stateMachine[state] as StateMachineEntry;

      console.log(`transition: ${currentState} -> ${state}`);
      currentStateMachine.onExit?.();
      currentState = state;
      newStateMachine.onEnter?.();
    },
  };

  // main interface

  function startTimer() {
    stateMachine.transition("start");
  }

  function stopTimer() {
    stateMachine.transition("stopped");
  }

  function resetTimer() {
    stateMachine.transition("reset");
  }

  // utilities

  function startInterval(callback: () => void): NodeJS.Timeout {
    return setInterval(callback, 1000);
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

  // SVG Display
  let maxArcLength = 314;
  let progressValue = 0;
  $: progressValue = percentLeft * (maxArcLength / 100);
  let arc: HTMLElement | null;
  $: if (arc) {
    arc.style.strokeDashoffset = progressValue.toString();
  }

  // Canvas Display
  let display: CanvasRenderingContext2D | null;
  let cw = 256;
  let ch = 256;
  let r = 117;

  $: if (document.getElementById("circleDisplay")) {
    if (!display) {
      initializeCanvas();
    }
    renderDisplay(percentLeft);
  }

  onMount(() => {
    initializeCanvas();
  });

  function initializeCanvas() {
    let canvas = document.getElementById("circleDisplay") as HTMLCanvasElement;
    if (canvas) {
      canvas = makeHiPPICanvas(canvas);
      display = canvas.getContext("2d");
      arc = document.querySelector("#progressArc");
      renderDisplay(100);
    }
  }

  function renderDisplay(percent: number) {
    if (!display) {
      console.log("Couldn't render display");
      return;
    }

    let startingRadian = 4.72; // top of circle is 1.5π
    let endingRadian = (percent / 100) * 2 * Math.PI; // draw clockwise to percent of total circle

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
    display.arc(
      cw / 2,
      ch / 2,
      r,
      startingRadian,
      startingRadian + endingRadian
    ); //arc(x,y,radius,start,stop)
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
    canvas.getContext("2d")?.setTransform(PIXEL_RATIO, 0, 0, PIXEL_RATIO, 0, 0);
    return canvas;
  }

  type DisplayStyle = "rectangle" | "circle" | "svg";
  let timerStyle: DisplayStyle = "circle";
</script>

<div class="flex flex-wrap justify-evenly dark:text-white">
  <div
    id="boxingTimer"
    class="w-72 border border-purple-700 rounded-lg pb-4 my-4 dark:bg-indigo-900 dark:text-white"
  >
    <p class="text-2xl text-center">Boxing Timer</p>

    <div class="text mb-4 flex justify-evenly space-x-4">
      <div>Round: {completedRounds + 1}</div>
      <div>State: {currentState}</div>
    </div>

    <div
      class="mx-auto h-24 w-64 bg-gray-300 text-6xl flex items-center justify-center font-bold
			rounded dark:text-white"
      class:hidden={!(timerStyle === "rectangle")}
    >
      {formatTime(timeLeft)}
    </div>

    <div
      class="relative h-64 w-64 mx-auto flex items-center justify-center dark:text-white"
      class:hidden={!(timerStyle === "circle")}
    >
      <canvas height={ch} width={cw} id="circleDisplay" />
    </div>

    <div
      class="relative h-64 w-64 mx-auto flex items-center justify-center"
      class:hidden={!(timerStyle === "svg")}
    >
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
          clip-path="url(#clip)"
        />
        <use
          xlink:href="#circle"
          id="progressArc"
          stroke="#e5f6f8"
          stroke-width="20"
          fill="none"
          clip-path="url(#clip)"
        />
        <text
          id="svgTime"
          class="font-bold text-2xl dark:stroke-white dark:fill-white"
          x="50%"
          y="51%"
          text-anchor="middle"
          alignment-baseline="middle"
        >
          {formatTime(timeLeft)}
        </text>
      </svg>
    </div>

    <div id="timerControls" class="mt-4 mx-4 flex justify-between">
      <button
        class="bg-green-200 dark:bg-green-700 py-1 px-3 rounded-lg border border-green-700"
        on:click={startTimer}
        disabled={!(currentState === "ready" || currentState === "stopped")}
      >
        start
      </button>
      <button
        class="bg-yellow-200 dark:bg-yellow-700 py-1 px-3 rounded-lg border border-yellow-700"
        on:click={stopTimer}
        disabled={!(currentState === "working" || currentState === "resting")}
      >
        stop
      </button>
      <button
        class="bg-red-200 dark:bg-red-700 py-1 px-3 rounded-lg border border-red-700"
        on:click={resetTimer}
      >
        reset
      </button>
    </div>
  </div>

  <div
    id="boxingTimerSettings"
    class="w-72 border border-purple-700 rounded-lg pb-4 align-top text-left my-4"
  >
    <p class="text-2xl text-center">Settings</p>

    <div id="roundTimeControls" class="mt-4 mx-4">
      Round Time:
      <input
        id="interval"
        class="ml-2 mr-1 w-16 rounded text-center border border-gray-600 dark:text-black"
        bind:value={humanRoundTime}
      />
    </div>

    <div id="restTimeControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={takeRestRound} />
      Rest Time:
      <input
        class="ml-2 mr-1 w-8 rounded text-center border border-gray-600 dark:text-black"
        bind:value={humanRestTime}
      />
      seconds
    </div>

    <hr class="my-4" />

    <div id="soundControls" class="mt-4 mx-4">
      <input
        class="mr-2 border border-gray-600"
        type="checkbox"
        bind:checked={playSounds}
      />
      Play Round Begin/End Sounds
    </div>

    <div id="intervalControls" class="mt-4 mx-4">
      <input class="mr-2" type="checkbox" bind:checked={playIntervalSound} />
      Interval Sound:
      <input
        id="interval"
        class="ml-2 mr-1 w-8 rounded text-center border border-gray-600 dark:text-black"
        bind:value={humanIntervalTime}
      />
      seconds
    </div>

    <hr class="my-4" />

    <div id="displayStyle" class="mt-4 mx-4">
      Timer Display Style
      <div class="mt-2 ml-4 flex flex-col">
        <label>
          <input type="radio" bind:group={timerStyle} value={"rectangle"} />
          Rectangle
        </label>
        <label>
          <input type="radio" bind:group={timerStyle} value={"circle"} />
          Circle (Canvas)
        </label>
        <label>
          <input type="radio" bind:group={timerStyle} value={"svg"} />
          Circle (SVG)
        </label>
      </div>
    </div>
  </div>
</div>

<p class="mb-4">
  Completed Rounds: {completedRounds} ({formatTime(
    completedRounds * roundTime
  )})
</p>

<style lang="postcss">
  /* p {
    @apply mt-4;
  }
  button {
    @apply py-2 px-4 rounded;
  }
  hr {
    @apply block my-4;
  } */
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
  /* svg {
    @apply w-64 h-64;
  }
  svg text {
    @apply font-bold;
  } */
</style>
