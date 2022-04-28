# ND1 app
<span>
<figure>
    <img src="/images/ND1_calc2.jpg" width="150">
    <!-- <figcaption>Some objects on the stack</figcaption> -->
</figure>
<figure>
    <img src="/images/ND1_calc.jpg" width="150">
    <!-- <figcaption>20 ways to use +</figcaption> -->
</figure>
<figure>
    <img src="/images/ND1_graph.jpg" width="150">
    <!-- <figcaption>Pinch-to-zoom and tap-to-trace</figcaption> -->
</figure>
<figure>
    <img src="/images/ND1_definition.jpg" width="150">
    <!-- <figcaption>Define keys, menus, and other UI</figcaption> -->
</figure>
<figure>
    <img src="/images/ND1_database.jpg" width="150">
    <!-- <figcaption>Save to cloud and share</figcaption> -->
</figure>
</span>


ND1 is an unusual iOS calculator app.

It's programmable by the user and powerful. That said, most people will find it weird to use because it uses ["Reverse Polish Notation (RPN)"](https://en.wikipedia.org/wiki/Reverse_Polish_notation) for entry: you need to feed it arguments on the "stack", before you invoke a function to operate on these arguments.

For example, you can do this

    1..100 divs

which gives you all divisors for the numbers from 1 to 100, as a list of lists.

Or

    1e14 1e5 modfib
    
which gives you the last 5 digits of the 10^14th Fibonacci number. (And uses modular matrix exponentiation internally.)
 
You can convert units like so
 
     10 'in' 'cm' convert
 
Or create a user function to calculate the side of a triangle, given an angle and two sides

    << -> A b c << c^2+b^2-2*b*c*cos(A) sqrt >>

(Where the three inputs have to pre-exist on the stack before this program, designated by << and >>, can be run/eval'ed. The three inputs become variables A, b, and c – that's what the arrow does.)

To calculate 2+2 interactively, you have to type
 
     2 2 +
 
which may seem strange and pedestrian but follows the same RPN principle.

ND1 also supports algebraic entry (like "2+2") with a tap on its command line, but honestly, it's not built for that.

What it's ***really*** built for is this:
 - people to have fun programming it in [RPL+](http://naivedesign.com/ND1/ND1_Reference__RPL+_Quick_Ref.html) or JavaScript with the built-in editor
 - people to have fun experimenting with building new calculation tools
 - people to share their creations

ND1 can solve [Project Euler](https://projecteuler.net) problems and is probably one of very few tools anyone *can* use on a phone for a task like this.

It kind of specializes in curiously strong 5- to 15-liners that solve math problems.

Like,

    << 10e6 primes
       decr            @ phi(x) of prime is x-1
       { real phi } { real isPowerOf2 } doUntil
       swap log2 +     @ calc totient chain length
       { real 25-2 == } select
       total
    >>

to compute the primes before 10 million, calculate Euler totient chain lengths for each (using `phi` and a log2 trick when phi returns a power of two), and [count all the ones that are 25 in length](https://projecteuler.net/problem=214).

Some users use it successfully to automate their daily calculation needs.

## Features

You can read up on features [here](http://naivedesign.com/ND1/Specs.html), but in a nutshell: there are ~2,000 functions over a variety of *types* ND1 can calculate with: real numbers, complex numbers, lists/vectors/matrices, symbolic expressions, fractions, continuous fractions, and more.
Users can program it in [RPL+](http://naivedesign.com/ND1/ND1_Reference__RPL+_Quick_Ref.html) and JavaScript and can even [add new types](http://naivedesign.com/ND1/ND1_Reference__Custom_Types.html) to calculate with (like Color or Chemical Formula).

Folders with data and/or code can be stored in the cloud and exchanged with other users. 

Users can rearrange keys, the contents of soft-menus, and build new calculators from scratch, composing a few kinds of UI elements into something new and connecting it all up with code. Those kind of creations can be uploaded and shared, too.

## Technically speaking

The app is a native Objective-C Cocoa/UIKit app that runs a JavaScript math and execution environment, called [MorphEngine](https://github.com/oliverue/morphengine), in a web view. The keys and all UI you see is native, but the calculator's display (stack and graphics output, inline or fullscreen) is HTML5.

Graphs, plots, and images (which you may generate [with code](http://naivedesign.com/ND1/The_Fib_Triangle.html)) use HTML5 Canvas.

Following best practice on iOS, CoreData is used and calculator definitions are stored in .sqlite models.

A compiler compiler is used to produce an expression parser from a [definition](CalculateParserDefinition.txt).

The JS and native parts of the app are glued together through a quite extensive WebView bridge. SQLite is ultimately used to persist user data that's created in JS and that includes variables, program code, and possibly binary data. When you tap the calculator tab all this data flows from native to JS through the bridge. When you store items in JS, the native backend is automatically updated.

There're very few external dependencies from both the JS and native worlds.

Outwardly, the app is a RPN/RPL-style calculator with a feature set of a much modernized HP-28C or HP-50g with weird extensions like RPL+, array processing, ranges, etc.

But inside, the app is a dynamic JavaScript runtime: 
  - RPL and RPL+ run in an interpreter inside of JavaScript and can call any of the JavaScript functions. (Which look like normal functions and need to know nothing of the stack.)
  - More complex types are layered on top of JavaScript and operators are routed to the correct types implementing them. (Where the routing depends on the seen types on the stack.)
  - A chain of JavaScript "with()" operators is used to blend function collections and user data into context available to user-written JavaScript. That means, JavaScript code can all of a sudden call functions like `divs` or `phi` (or a proper `sin` that returns 0 for `pi`, unlike Math.sin()) or reference user variables, without any decoration involved
  - There're two mechanisms through which new code can be injected into the execution engine. That permits app users to extend the calculator with functions and types as if they were built-in, and build specialized new tools 
  - Some code fragments written in RPL+ are "morphed" into JavaScript. Imagine writing powerful and convenient lo-code that runs at the speed of the underlying VM. The intention is to push this further and offer a WebGL/GLSL backend as well

The whole idea to built this app arose from a desire to play with code morphing and offer remarkable programmability ***and*** extensibility to the user.

### Building the app

Clone the repository and open the .xcodeproject file in Xcode. Xcode will do the rest.

There's one important manual prep step: you also need to clone [MorphEngine](https://github.com/oliverue/morphengine) and move the .js and .html files into the Resources folder. The shipping app would uglify the code.

### Derivatives

At some point, I fantasized about an Android version. Clearly, the basic JS engine (which constitutes half of the codebase) is completely portable (and was used successfully in an experimental build for Kindle), but writing the native UI for calculator and user data management would be a big task.
Just building a single hard-coded calculator using the engine, however, would be much easier. The user would still get to create variables and programs (because this is all handled in JS) but the data would have to be persisted (through LocalStorage or a bridge).

## State of affairs

This is a "historical" project in a sense: most of the code was written 2010-2012, with two modernization cycles due to  changes in iOS in 2016 (for iOS 7/8) and 2022 (for iOS 10+).

It doesn't use Storyboards and uses Objective-C instead of Swift.

There're still a few open [issues](./ISSUES.md) from the last push. And a long [wish list](./TODO.md).

I strive to continue to publish ND1 on the App Store and will, with this move to OpenSource, change it from a paid app to a free app. However, my availability to maintain the app may vary.

I will move the documentation, currently located on naivedesign.com, into this repo. It's not super-easy because I used iWeb to build it, which is no longer supported and generated code with absolute web site references everywhere.

"Philosophically" this app is in a strange place. It's 1000x more powerful than your typical calculator, but also 1000x less powerful than something like Mathematica / the Wolfram Language. What to make of it? I'm not sure (but I somehow use it almost every day).

Maybe you feel like digging in and bringing this app to the next level. Or maybe you can use some parts.
