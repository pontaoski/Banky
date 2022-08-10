import { defineConfig } from "vite"

export default defineConfig({
    root: "./Assets",
    base: "/Public/",
    build: {
        manifest: true,
        emptyOutDir: true,
        assetsDir: "",
        outDir: "../Public/",
        rollupOptions: {
            input: {
                code: "app.js"
            }
        }
    }
})
