# Upsilon Garden

## Setup

### Elixir install

See [Elixir-lang install page](https://elixir-lang.org/install.html)

### Node.js install 

See [Node.js download page](https://nodejs.org/en/download/)

### Local setup

Execute `mix deps.get`; it might ask you to update hex local, do so. Might take a while
Execute `npm install && node node_modules/brunch/bin/brunch build`; Might take a while as well
Execute `mix deps.compile`; Might take a while as well

### DB Configuration

This app need a PostgresSQL instance and this need to be configured thus.
A user must be provided that has Database creation rights. 

Create files in config folder: 

*dev.secret.exs*

> use Mix.Config
>
> # Configure your database
> config :upsilon_garden, UpsilonGarden.Repo,
>  adapter: Ecto.Adapters.Postgres,
>  username: <fill in>,
>  password: <fill in>,
>  database: <fill in>,
>  hostname: <fill in>,
>  pool_size: 10
>

Execute `mix phx.gen.secret` and get generated key

add to the file

> config :upsilon_garden, UpsilonGardenWeb.Endpoint,
>  secret_key_base: "<put generated key>"

Also, create a copy and alter database name for *test.secret.exs*, if you plan to use it in prod, do so for prod.secret.exs as well ;)

Once all this is done ... 

Execute `mix do ecto.create, ecto.migrate`
Execute `MIX_ENV=test mix do ecto.create, ecto.migrate`

Both request will generate new database. You may have to use `mix ecto.migrate`after pulling again. 

#### Rebuilding from scratch

If you want to rebuild database from scratch you may do so: 

Execute `mix do ecto.drop, ecto.create, ecto.migrate`
Don't forget to update *test* environment as well. 

### Usage

#### Execute Test

Execute `mix test`

#### Start server

Execute `mix phx.server`

Website will be up on http://127.0.0.1:4000/garden

#### Start server in CLI mode: 

Execute `iex -S mix phx.server`

Website will be up on http://127.0.0.1:4000/garden

#### Start app in CLI mode: 

Execute `iex -S mix`

## Done

### Generate a Garden based on Rules

Based on Garden Context rules, will generate a garden with multiples components dispatched around. Generates sources as well that are ponctual and distinct components around the garden as well, thus allowing a wider variation of components available. 

These contexts will in the end be stored and mapped to "Locations" which gardens attached to them. Thus we ensure that garden vary but stay coherent with one another. 

### Generate a Plant based on Rules

Just like garden, plants follow a set of rules defined in Plant and Root Context. 
This context definition tell how roots should be disposed, what they can and can't absorb.

Not yet done, but a Plant context should also hold Cycle Context which defines how a plant Grows

### Plant may grow

A plant is defined by a tree of Cycles. 
Each cycle define needs of each part of a plant to grow. It also define what happens when these need arent met and ultimately how a plant may die.
Each cycle may have multiple evolutions step, each step explains what happend when cycle needs are met in term of stat increase. Each step may put online new cycles describing new plants part. 

Most plant will begin with a single Cycle *Roots* , then on next root evolution step, new *Leaves* cycles will begin, which in turn will begin *Flowers* cycle and so on. 

### Plant may Absorb

Each plant in a garden has content, whose max size is defined by actives cycles. 
Each turn (15s), all plants absorb content from the garden, and more specifically from blocs where their roots are located.

Each root may absorb several components of the bloc, and there are three distinct absorption mechanism implemented

* Keep: Keep the component whole
* Trunc in: Split the component in two based on Root ability to absorb and keep both
* Truc out: Split the component in two based on Root ability to absorb and keep only the one selected by roots abilities. 

Each root may also reject what it justs absorbed. Ideally it should also be able to reject from store, but that's quite another subject (and quite complex at that)

If several plants roots are on a single bloc, what a root rejects can be absorbed by other plants, works also with trunced out stuff. 

### Projection

Engine isn't meant to check every 15s and do intensive computation there. It will instead compute a projection. 
This projection will tell what should happend from state T and when state should change, based on several information like, available content space in plants, events, cycles completions. 

When a garden is requested for display, an update should be triggered and thus projection generated and applied up until Now is reached. 

### Basic display

Based on Garden layout shows where the plant is, how is its root layed out, where sources are and so on. There was a page where you could click and see details for each block but that's gone ATM ;)

## Next step

### Novice Gameplay

This is mostly centered on a few actions: 

* Select a "Seed" and plant it: Generate a plant at the appointed garden segment. 
* Water a segment
* Control Water level of a segment
* See the plant grow (and/or) wither due to lack (or over aboundance) of water.
* Harvest a plant whenever the user want. 
* Get new seed from the harvested plant (if able) 

This require a few new features in the engine: 

* Default water level on segment
* Segment water retension
* Adding events (and keeping track of them in Projection) to a segment. 
* Compute plant water level ( based on root presence per segments )
* Turn by turn water level checks and apply its penality if necessary
* Add GUI Control: Check water level on segment; only provide minimal informations: 
** Totally dry ( < 10% )
** Dry ( < 30% )
** OK ( < 60% )
** Mud ( < 80% )
** Watery ( < 100% )
* Add GUI Control: Water segment : Create an event on a given Segment, add 30% (+ apply segment water retension) of water level for 8 hours.
* Add GUI Control: Check Plant Health: tell whether it looks good or not (based on global structure points )
* Add GUI Control: Plant Seed
* Add GUI Control: Harvest Plant


