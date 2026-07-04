import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import * as path from "node:path";

// https://vite.dev/config/
export default defineConfig({
    plugins: [react(), tailwindcss()],
    resolve: {
        alias: {
            '@': path.resolve(__dirname, '.'),
        },
    },
    server: {
        proxy: {
            // Mirrors the CloudFront /api behavior locally: forward /api/* to the
            // local Spring Boot backend and strip the /api prefix (the backend
            // serves at the root, same as in production behind CloudFront).
            '/api': {
                target: 'http://localhost:4566/_aws/execute-api/665093f7/',   // adjust to your backend's local port
                changeOrigin: true,
                rewrite: (p) => p.replace(/^\/api/, ''),
            },
        },
    },
})
