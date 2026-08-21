import { defineConfig } from "vite";
import { spawn, execSync } from "node:child_process";
let watcher: ReturnType<typeof spawn> | null = null;

export default defineConfig({
  plugins: [{
    name: "rescript-auto-build",
    apply: () => true,

    configureServer() {
      if (watcher) return;
      watcher = spawn("pnpm", ["res:build", "-w"], {
        stdio: "inherit",
        shell: true,
      });

      const stop = () => {
        watcher?.kill();
        watcher = null;
      };
      process.on("exit", stop);
      process.on("SIGINT", stop);
      process.on("SIGTERM", stop);
    },

    buildStart() {
      if (process.env.NODE_ENV !== "development") execSync("pnpm res:build", { stdio: "inherit" });
    },
  }
],
  server: {
    watch: {
      ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
    },
  },
});
