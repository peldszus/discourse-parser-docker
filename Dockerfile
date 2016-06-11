FROM java:7

# Based on the Dockerfile vrann/discourse-parser-docker
# from Eugene Tulika "vranen@gmail.com"
# Thanks to Wladimir for subprocess patch

MAINTAINER Andreas Peldszus "peldszus@uni-potsdam.de"

RUN apt-get update \
	&& apt-get install -y python python-dev python-pip python-virtualenv \
	&& rm -rf /var/lib/apt/lists/*

RUN wget http://pyyaml.org/download/pyyaml/PyYAML-3.09.tar.gz \
	&& tar -zxf PyYAML-3.09.tar.gz \
	&& cd PyYAML-3.09 \
	&& python setup.py install \
	&& cd .. && rm -rf PyYAML-3.09 PyYAML-3.09.tar.gz

RUN wget https://pypi.python.org/packages/source/n/nltk/nltk-2.0b9.tar.gz \
	&& tar -zxf nltk-2.0b9.tar.gz \
	&& cd nltk-2.0b9 \
	&& python setup.py install \
	&& cd .. && rm -rf nltk-2.0b9 nltk-2.0b9.tar.gz

RUN wget http://www.cs.toronto.edu/~weifeng/software/discourse_parse-2.01.tar.gz \
	&& tar -zxf discourse_parse-2.01.tar.gz \
	&& rm -rf discourse_parse-2.01.tar.gz

RUN wget https://github.com/downloads/chokkan/liblbfgs/liblbfgs-1.10.tar.gz \
	&& tar -zxf liblbfgs-1.10.tar.gz \
	&& cd liblbfgs-1.10 \
	&& ./configure --prefix=$HOME/local \
	&& make \
	&& make install \
	&& cd .. && rm -rf liblbfgs-1.10 liblbfgs-1.10.tar.gz

RUN cd gCRF_dist/tools/crfsuite/crfsuite-0.12 \
	&& chmod +x configure \
	&& sleep 1 \
	&& ./configure --prefix=$HOME/local --with-liblbfgs=$HOME/local \
	&& make \
	&& make install

RUN cd gCRF_dist/tools/crfsuite \
	&& cp $HOME/local/bin/crfsuite crfsuite-stdin \
	&& chmod +x crfsuite-stdin

# Test CRF suite
RUN cd gCRF_dist/tools/crfsuite \
	&& ./crfsuite-stdin tag -pi -m ../../model/tree_build_set_CRF/label/intra.crfsuite test.txt

# Patch crfsuite wrapper
ADD subprocess.patch .
RUN patch /gCRF_dist/src/classifiers/crf_classifier.py < /subprocess.patch

# Test discourse parser
RUN cd gCRF_dist/src \
	&& python sanity_check.py

CMD ["/bin/bash"]
