<script>
    import { btn } from "./buttons"
    import ServicesSadTest from './services_sad_test.svelte';
    import ServicesTranscribeTest from './services_transcribe_test.svelte';
    let url = 'demo/CarrieFisher10s.wav';
    let b1 = $state(false);
    let b2 = $state(false);
</script>

<style>
</style>

{#if b1}
    <ServicesSadTest {url} />
{:else}
    <div><button class="{btn}" onclick={() => b1 = true}>SAD Test</button></div>
{/if}
{#if b2}
    <ServicesTranscribeTest url={'https://coghealth.s3.amazonaws.com/' + url} />
{:else}
    <div><button class="{btn}" onclick={() => b2 = true}>Transcribe Test</button></div>
{/if}
