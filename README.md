Vim motion on speed! [![Build Status](https://travis-ci.org/haya14busa/vim-easymotion.png?branch=master)](https://travis-ci.org/haya14busa/vim-easymotion)
-----


DEPRECATION WARNING
-----
This repository is **DEPRECATED** because I became collaborator on the main Lokaltog/vim-easymotion repository(https://github.com/Lokaltog/vim-easymotion) and took over the project.

Please move back to the main Lokaltog/vim-easymotion repository.

Thank you for using my fork version!

I'll try to develop easymotion to make it more sophisticated on the main repository. The same as before.

### Attention for moving back to original vim-easymotion

I pushed all updates to the main repo, but I made small changes from this repository.

#### 1. I separated `SelectLines` & `SelectPhrase` as a different plugin.

`SelectLines` & `SelectPhrase` is not **motion** but **operator** and I could clean up the code by separating these function. These functions was implemented by supasorn(https://github.com/supasorn).

If you used these features or are interested in, please install these plugin in addition to vim-easymotion.

- https://github.com/haya14busa/vim-easyoperator-line
- https://github.com/haya14busa/vim-easyoperator-phrase

#### 2. Remove `<Plug>(easymotion-S)`
Attention: `S` is uppercase.

`easymotion-S` is same as `<Plug>(easymotion-bd-w)` and existed only for backward compatibility of this repository, so I remove this mapping. If you used this mapping, please use `<Plug>(easymotion-bd-w)` instead.


That's all.

Thank you again!
