import baker
import json
from path import path
from cytoolz import merge, join, groupby, pluck
from cytoolz.compatibility import iteritems
from cytoolz.curried import update_in
from itertools import starmap
from collections import deque
from lxml import etree, objectify
from scipy.io import savemat
from scipy.ndimage import imread
from sh import mv


def keyjoin(leftkey, leftseq, rightkey, rightseq):
    return starmap(merge, join(leftkey, leftseq, rightkey, rightseq))


def root(folder, filename, width, height):
    E = objectify.ElementMaker(annotate=False)
    return E.annotation(
            E.folder(folder),
            E.filename(filename),
            E.source(
                E.database('MS COCO 2014'),
                E.annotation('MS COCO 2014'),
                E.image('Flickr'),
                ),
            E.size(
                E.width(width),
                E.height(height),
                E.depth(3),
                ),
            E.segmented(0)
            )


def instance_to_xml(anno):
    E = objectify.ElementMaker(annotate=False)
    xmin, ymin, width, height = anno['bbox']
    return E.object(
            E.name(anno['category_id']),
            E.bndbox(
                E.xmin(xmin),
                E.ymin(ymin),
                E.xmax(xmin+width),
                E.ymax(ymin+height),
                ),
            )


@baker.command
def write_categories(coco_annotation, dst):
    content = json.loads(path(coco_annotation).expand().text())
    categories = tuple( d['name'] for d in content['categories'])
    savemat(path(dst).expand(), {'categories': categories})


def get_instances(coco_annotation):
    coco_annotation = path(coco_annotation).expand()
    content = json.loads(coco_annotation.text())
    categories = {d['id']: d['name'] for d in content['categories']}
    return categories, tuple(keyjoin('id', content['images'], 'image_id', content['instances']))

def rename(name, year=2014):
        out_name = path(name).stripext()
        out_name = out_name.split('_')[-1]
        out_name = '{}_{}'.format(year, out_name)
        return out_name


@baker.command
def mass_rename(src):
    files = path(src).expand().listdir('*.jpg')

    for f in files:
        print f
        mv(f, '{}{}'.format(f.dirname() / rename(f), f.ext))


@baker.command
def create_data(dbpath, subset, devkit, year=2014):
    annotations_path = path(dbpath).expand() / 'annotations/instances_{}2014.json'.format(subset)
    images_path = path(dbpath).expand() / 'images/{}2014'.format(subset)
    categories , instances= get_instances(annotations_path)
    devkit = path(devkit).expand()

    annotations_dst = devkit / 'VOC{}/Annotations'.format(year)
    imagesets_dst = devkit / 'VOC{}/ImageSets/Main/{}.txt'.format(year, subset)

    for i, instance in enumerate(instances):
        instances[i]['category_id'] = categories[instance['category_id']]

    for name, group in iteritems(groupby('file_name', instances)):
        img = imread(images_path / name)
        if img.ndim == 3 and img.shape[0] > 10 and img.shape[1] > 10:
            out_name = rename(name)
            annotation = root('VOC2014', '{}.jpg'.format(out_name), 
                              width=group[0]['width'], height=group[0]['height'])
            for instance in group:
                annotation.append(instance_to_xml(instance))
            etree.ElementTree(annotation).write(annotations_dst / '{}.xml'.format(out_name))
            imagesets_dst.write_text('{}\n'.format(out_name), append=True)
            print out_name
        else:
            print instance['file_name']


@baker.command
def category_set(category, vocdevkit, year='2014'):
    vocdevkit = path(vocdevkit).expand()
    dst = vocdevkit / 'VOC{year}/ImageSets/Main/{category}_{subset}.txt'
    annotations = vocdevkit / 'VOC{year}/Annotations/{filename}.xml'
    imageset = vocdevkit / 'VOC{year}/ImageSets/Main/{subset}.txt'
    template = '{filename} {present}\n'

    def f(imageset, annotations, year, dst, template, subset, category):
        imageset = path(imageset.format(year=year, subset=subset))
        dst = path(dst.format(year=year, category=category, subset=subset))
        if dst.exists():
            dst.write_text('')
        for name in imageset.lines(retain=False):
            anno = objectify.fromstring(path(annotations.format(year=year, filename=name)).text())
            if category in set(pluck('name', anno['object'])):
                present = 1
            else:
                present = -1

            dst.write_text(template.format(filename=name, present=present), append=True)
            print template.format(filename=name, present=present)

    f(imageset, annotations, year, dst, template, 'train', category)
    f(imageset, annotations, year, dst, template, 'val', category)


@baker.command
def all_sets(vocdevkit, dbpath, year='2014'):
    dbpath = path(dbpath).expand()
    vocdevkit = path(vocdevkit).expand()
    annotations = dbpath / 'annotations/instances_{}2014.json'.format('train')
    content = json.loads(annotations.text())
    categories = pluck('name', content['categories'])

    for category in categories:
        category_set(category, vocdevkit, year)


if __name__ == '__main__':
    baker.run()
