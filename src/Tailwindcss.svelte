<style global lang="postcss">
  @tailwind base;

  body {
    @apply font-sans;
  }

  label {
    display: block;
  }

  input,
  button,
  select,
  textarea {
    font-family: inherit;
    font-size: inherit;
    box-sizing: border-box;
    border: 1px solid #ccc;
    border-radius: 2px;
  }

  button:disabled {
    color: #999;
  }

  @tailwind components;
  @tailwind utilities;
</style>
