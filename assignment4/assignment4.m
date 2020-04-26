clear all; close all; clc

% Import book
book_fname = 'goblet_book.txt';
fid = fopen(book_fname,'r');
book_data = fscanf(fid,'%c');
fclose(fid);

book_chars = unique(book_data);
K = length(book_chars); % number of unique characters
