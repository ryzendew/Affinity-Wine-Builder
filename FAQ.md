# Frequently Asked Questions (FAQ)

### What is the motivation for this project?

- To apply ElementalWarrior's wine update, benefitting Affinity by Canva.
- It turns out that one needs an older build toolchain to build older wine releases.
- Wine built with NTsync improves parallel processing, more so if the CPU has many cores.

### What environment variables are helpful running DXVK with Affinity Studio?

From testing, setting two environment variables gives the best visual experience.
Do not install DXVK if you want OpenCL acceleration.

```sh
DXVK_ASYNC=0
DXVK_CONFIG="d3d9.deferSurfaceCreation = True; d3d9.shaderModel = 1"
```

