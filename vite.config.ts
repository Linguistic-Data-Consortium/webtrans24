import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { svelte } from '@sveltejs/vite-plugin-svelte';
 
export default defineConfig({
  plugins: [
    RubyPlugin(),
    svelte({ emitCss: false })
  ],
})
