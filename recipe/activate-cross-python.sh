#!/bin/bash

if [[ "${CONDA_BUILD:-0}" == "1" && "${CONDA_BUILD_STATE}" != "TEST" ]]; then
  $BUILD_PREFIX/bin/python -m crossenv $PREFIX/bin/python \
      --sysroot $CONDA_BUILD_SYSROOT \
      --without-pip $BUILD_PREFIX/venv \
      --sysconfigdata-file $PREFIX/lib/python$PY_VER/${_CONDA_PYTHON_SYSCONFIGDATA_NAME}.py

  # For recipes using {{ PYTHON }}
  cp $BUILD_PREFIX/venv/cross/bin/python $PREFIX/bin/python

  # For recipes looking at python on PATH
  rm $BUILD_PREFIX/bin/python
  echo "#!/bin/bash" > $BUILD_PREFIX/bin/python
  echo "exec $PREFIX/bin/python \"\$@\"" >> $BUILD_PREFIX/bin/python
  chmod +x $BUILD_PREFIX/bin/python

  rm -rf $BUILD_PREFIX/venv/cross
  if [[ -d "$PREFIX/lib/python$PY_VER/site-packages/" ]]; then
    find $PREFIX/lib/python$PY_VER/site-packages/ -name "*-darwin.so" -exec rm {} \;
    rsync -a -I $PREFIX/lib/python$PY_VER/site-packages/ $BUILD_PREFIX/lib/python$PY_VER/site-packages/
    rm -rf $PREFIX/lib/python$PY_VER/site-packages
    mkdir $PREFIX/lib/python$PY_VER/site-packages
  fi
  rm -rf $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  ln -s $BUILD_PREFIX/lib/python$PY_VER/site-packages $BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
  sed -i.bak "s@$BUILD_PREFIX/venv/lib@$BUILD_PREFIX/venv/lib', '$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages@g" $PYTHON

  if [[ "${PYTHONPATH}" != "" ]]; then
    _CONDA_BACKUP_PYTHONPATH=${PYTHONPATH}
  fi
  export PYTHONPATH=$BUILD_PREFIX/venv/lib/python$PY_VER/site-packages
fi
