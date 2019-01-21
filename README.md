# VVVV.Gea.NaiveGPU
Naive physics simulation on GPU

### Info
Rope and Cloth physics based on a simple Springs algorithm, verlet integration based.
An Euler GPU particles system can be managed within the same architecture
Particles, ropes and clothes can be created and managed separately.
Each entity of the system is called "group" (due to the fact that is a group of threads on the unique GPU buffer that holds all the data) (I know, I would call it differently now, but...).
You can apply forces, constraints and deformers to individual groups or to all of them.

### Disclaim
This is a software prototype born one year ago, built in crazy hurry for a project and full of compromizes and probably unfinished parts.
On one end I feel bit unconfortable in releasing it since nowadays I would sctructure it quite differently. It looks so imperfect to me...
..but on the other ends it contains some principles that might be interesting for other users. This is why i decided to publish it, in it's unperfect state, just adding some comments to the patches hoping it gets bit more understandable. you can always ask me on the forum...
Ah, I didn't have really time to prepare nice help patches or multiple example scenarios. I just have one example patch in which you see most of the stuff at work...

### Required Packs
- dx11
- dx11.Particles
- InstanceNoodles
- Happy.fxh


