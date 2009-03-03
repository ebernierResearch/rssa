#   R package for Singular Spectrum Analysis
#   Copyright (c) 2008 Anton Korobeynikov <asl@math.spbu.ru>
#   
#   This program is free software; you can redistribute it 
#   and/or modify it under the terms of the GNU General Public 
#   License as published by the Free Software Foundation; 
#   either version 2 of the License, or (at your option) 
#   any later version.
#
#   This program is distributed in the hope that it will be 
#   useful, but WITHOUT ANY WARRANTY; without even the implied 
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
#   PURPOSE.  See the GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public 
#   License along with this program; if not, write to the 
#   Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
#   MA 02139, USA.

#   Routines for operations with hankel matrices.

tcirc.old <- function(F, L = (N - 1) %/% 2) {
  N <- length(F); K = N - L + 1;
  .res <- list();
  .res$C <- as.vector(fft(c(F[K:N], F[1:(K-1)])));
  .res$L <- L;
  return (.res);
}

hmatmul.old <- function(C, v) {
  v <- as.vector(fft(C$C * fft(c(rev(v), rep(0, C$L-1))), inverse = TRUE));
  Re((v/length(C$C))[1:C$L]);
}

hankel <- function(X, L) {
  if (is.matrix(X) && nargs() == 1) {
     L <- nrow(X); K <- ncol(X); N <- K + L - 1;
     left  <- c(1:L, L*(2:K));
     right <- c(1+L*(0:(K-1)), ((K-1)*L+2):(K*L));
     v <- sapply(1:N, function(i) mean(X[seq.int(left[i], right[i], by = L-1)]));
     return (v);
  }

  # Coerce output to vector, if necessary
  if (!is.vector(X))
    X <- as.vector(X);
  N <- length(X);
  if (missing(L))
    L <- (N - 1) %/% 2;
  K <- N - L + 1;
  outer(1:L, 1:K, function(x,y) X[x+y-1]);
}

.hankelize.one <- function(U, V) {
  storage.mode(U) <- storage.mode(V) <- "double";
  .Call("hankelize_one", U, V);
}

.hankelize.multi <- function(U, V) {
  storage.mode(U) <- storage.mode(V) <- "double";
  .Call("hankelize_multi", U, V);
}

new.hmat <- function(F,
                     L = (N - 1) %/% 2) {
  N <- length(F);
  storage.mode(F) <- "double";
  storage.mode(L) <- "integer";
  h <- .Call("initialize_hmat", F, L);
}

hcols <- function(h) {
  .Call("hankel_cols", h)
}

hrows <- function(h) {
  .Call("hankel_rows", h)
}

is.hmat <- function(h) {
  .Call("is_hmat", h)
}

hmatmul <- function(hmat, v, transposed = FALSE) {
  storage.mode(v) <- "double";
  storage.mode(transposed) <- "logical";
  .Call("hmatmul", hmat, v, transposed);
}

.decompose.ssa.hankel <- function(this,
                                  neig = min(50, L, K),
                                  ...) {
  N <- this$length; L <- this$window; K <- N - L + 1;
  F <- .get(this, "F");

  h <- new.hmat(F, L = L);

  S <- propack_svd(h, neig = neig, ...);

  # Save results
  .set(this, "hmat", h);
  .set(this, "lambda", S$d);
  if (!is.null(S$u))
    .set(this, "U", S$u);
  if (!is.null(S$v))
    .set(this, "V", S$v);
}

mes <- function(N = 1000, L = (N %/% 2), n = 50) {
  F <- rnorm(N);
  v <- rnorm(N - L + 1);
  C <- tcirc.old(F, L = L);
  X <- hankel(F, L = L);
  h <- new.hmat(F, L = L);
  st1 <- system.time(for (i in 1:n) X %*% v);
  st2 <- system.time(for (i in 1:n) hmatmul.old(C, v));
  st3 <- system.time(for (i in 1:n) hmatmul(h, v));
  c(st1[["user.self"]], st2[["user.self"]], st3[["user.self"]]);
}


#Rprof();
#for (i in 1:250) {
#  r1 <- X %*% v;
#  r2 <- hmul(C, v);
#}
#Rprof(NULL);
#print(max(abs(r1-r2)));
#summaryRprof();